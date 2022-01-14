# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning do
  include Database::PartitioningHelpers
  include Database::TableSchemaHelpers

  let(:connection) { ApplicationRecord.connection }

  around do |example|
    previously_registered_models = described_class.registered_models.dup
    described_class.instance_variable_set('@registered_models', Set.new)

    previously_registered_tables = described_class.registered_tables.dup
    described_class.instance_variable_set('@registered_tables', Set.new)

    example.run

    described_class.instance_variable_set('@registered_models', previously_registered_models)
    described_class.instance_variable_set('@registered_tables', previously_registered_tables)
  end

  describe '.register_models' do
    context 'ensure that the registered models have partitioning strategy' do
      it 'fails when partitioning_strategy is not specified for the model' do
        model = Class.new(ApplicationRecord)
        expect { described_class.register_models([model]) }.to raise_error /should have partitioning strategy defined/
      end
    end
  end

  describe '.sync_partitions_ignore_db_error' do
    it 'calls sync_partitions' do
      expect(described_class).to receive(:sync_partitions)

      described_class.sync_partitions_ignore_db_error
    end

    [ActiveRecord::ActiveRecordError, PG::Error].each do |error|
      context "when #{error} is raised" do
        before do
          expect(described_class).to receive(:sync_partitions)
            .and_raise(error)
        end

        it 'ignores it' do
          described_class.sync_partitions_ignore_db_error
        end
      end
    end

    context 'when DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP is set' do
      before do
        stub_env('DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP', '1')
      end

      it 'does not call sync_partitions' do
        expect(described_class).to receive(:sync_partitions).never

        described_class.sync_partitions_ignore_db_error
      end
    end
  end

  describe '.sync_partitions' do
    let(:table_names) { %w[partitioning_test1 partitioning_test2] }
    let(:models) do
      table_names.map do |table_name|
        Class.new(ApplicationRecord) do
          include PartitionedTable

          self.table_name = table_name
          partitioned_by :created_at, strategy: :monthly
        end
      end
    end

    before do
      table_names.each do |table_name|
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name} (
            id serial not null,
            created_at timestamptz not null,
            PRIMARY KEY (id, created_at))
          PARTITION BY RANGE (created_at);
        SQL
      end
    end

    it 'manages partitions for each given model' do
      expect { described_class.sync_partitions(models)}
        .to change { find_partitions(table_names.first).size }.from(0)
        .and change { find_partitions(table_names.last).size }.from(0)
    end

    context 'when no partitioned models are given' do
      it 'manages partitions for each registered model' do
        described_class.register_models([models.first])
        described_class.register_tables([
          {
            table_name: table_names.last,
            partitioned_column: :created_at, strategy: :monthly
          }
        ])

        expect { described_class.sync_partitions }
          .to change { find_partitions(table_names.first).size }.from(0)
          .and change { find_partitions(table_names.last).size }.from(0)
      end
    end
  end

  describe '.report_metrics' do
    let(:model1) { double('model') }
    let(:model2) { double('model') }

    let(:partition_monitoring_class) { described_class::PartitionMonitoring }

    context 'when no partitioned models are given' do
      it 'reports metrics for each registered model' do
        expect_next_instance_of(partition_monitoring_class) do |partition_monitor|
          expect(partition_monitor).to receive(:report_metrics_for_model).with(model1)
          expect(partition_monitor).to receive(:report_metrics_for_model).with(model2)
        end

        expect(Gitlab::Database::EachDatabase).to receive(:each_model_connection)
          .with(described_class.__send__(:registered_models))
          .and_yield(model1)
          .and_yield(model2)

        described_class.report_metrics
      end
    end

    context 'when partitioned models are given' do
      it 'reports metrics for each given model' do
        expect_next_instance_of(partition_monitoring_class) do |partition_monitor|
          expect(partition_monitor).to receive(:report_metrics_for_model).with(model1)
          expect(partition_monitor).to receive(:report_metrics_for_model).with(model2)
        end

        expect(Gitlab::Database::EachDatabase).to receive(:each_model_connection)
          .with([model1, model2])
          .and_yield(model1)
          .and_yield(model2)

        described_class.report_metrics([model1, model2])
      end
    end
  end

  describe '.drop_detached_partitions' do
    let(:table_names) { %w[detached_test_partition1 detached_test_partition2] }

    before do
      table_names.each do |table_name|
        connection.create_table("#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{table_name}")

        Postgresql::DetachedPartition.create!(table_name: table_name, drop_after: 1.year.ago)
      end
    end

    it 'drops detached partitions for each database' do
      expect(Gitlab::Database::EachDatabase).to receive(:each_database_connection).and_yield

      expect { described_class.drop_detached_partitions }
        .to change { Postgresql::DetachedPartition.count }.from(2).to(0)
        .and change { table_exists?(table_names.first) }.from(true).to(false)
        .and change { table_exists?(table_names.last) }.from(true).to(false)
    end

    def table_exists?(table_name)
      table_oid(table_name).present?
    end
  end
end
