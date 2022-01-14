# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::DeletedRecord, type: :model do
  let_it_be(:table) { 'public.projects' }

  describe 'class methods' do
    let_it_be(:deleted_record_1) { described_class.create!(fully_qualified_table_name: table, primary_key_value: 5) }
    let_it_be(:deleted_record_2) { described_class.create!(fully_qualified_table_name: table, primary_key_value: 1) }
    let_it_be(:deleted_record_3) { described_class.create!(fully_qualified_table_name: 'public.other_table', primary_key_value: 3) }
    let_it_be(:deleted_record_4) { described_class.create!(fully_qualified_table_name: table, primary_key_value: 1) } # duplicate

    describe '.load_batch_for_table' do
      it 'loads records and orders them by creation date' do
        records = described_class.load_batch_for_table(table, 10)

        expect(records).to eq([deleted_record_1, deleted_record_2, deleted_record_4])
      end

      it 'supports configurable batch size' do
        records = described_class.load_batch_for_table(table, 2)

        expect(records).to eq([deleted_record_1, deleted_record_2])
      end
    end

    describe '.mark_records_processed' do
      it 'updates all records' do
        records = described_class.load_batch_for_table(table, 10)
        described_class.mark_records_processed(records)

        expect(described_class.status_pending.count).to eq(1)
        expect(described_class.status_processed.count).to eq(3)
      end
    end
  end

  describe 'sliding_list partitioning' do
    let(:connection) { described_class.connection }
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    describe 'next_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition.value }

      subject(:value) { described_class.partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition has records' do
        before do
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 1, status: :processed)
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 2, status: :pending)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the first record of the partition is older than PARTITION_DURATION' do
        before do
          described_class.create!(
            fully_qualified_table_name: 'public.table',
            primary_key_value: 1,
            created_at: (described_class::PARTITION_DURATION + 1.day).ago)

          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 2)
        end

        it { is_expected.to eq(true) }

        context 'when the lfk_automatic_partition_creation FF is off' do
          before do
            stub_feature_flags(lfk_automatic_partition_creation: false)
          end

          it { is_expected.to eq(false) }
        end
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition.value }

      subject(:value) { described_class.partitioning_strategy.detach_partition_if.call(active_partition) }

      context 'when the partition contains unprocessed records' do
        before do
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 1, status: :processed)
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 2, status: :pending)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the partition contains only processed records' do
        before do
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 1, status: :processed)
          described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 2, status: :processed)
        end

        it { is_expected.to eq(true) }

        context 'when the lfk_automatic_partition_dropping FF is off' do
          before do
            stub_feature_flags(lfk_automatic_partition_dropping: false)
          end

          it { is_expected.to eq(false) }
        end
      end
    end

    describe 'the behavior of the strategy' do
      it 'moves records to new partitions as time passes', :freeze_time do
        # We start with partition 1
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([1])

        # it's not a day old yet so no new partitions are created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([1])

        # add one record so the next partition will be created
        described_class.create!(fully_qualified_table_name: 'public.table', primary_key_value: 1)

        # after traveling forward a day
        travel(described_class::PARTITION_DURATION + 1.second)

        # a new partition is created
        partition_manager.sync_partitions

        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([1, 2])

        # and we can insert to the new partition
        expect { described_class.create!(fully_qualified_table_name: table, primary_key_value: 5) }.not_to raise_error

        # after processing old records
        LooseForeignKeys::DeletedRecord.for_partition(1).update_all(status: :processed)

        partition_manager.sync_partitions

        # the old one is removed
        expect(described_class.partitioning_strategy.current_partitions.map(&:value)).to eq([2])

        # and we only have the newly created partition left.
        expect(described_class.count).to eq(1)
      end
    end
  end
end
