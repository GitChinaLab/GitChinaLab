# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresPartition, type: :model do
  let(:schema) { 'gitlab_partitions_dynamic' }
  let(:name) { '_test_partition_01' }
  let(:identifier) { "#{schema}.#{name}" }

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE public._test_partitioned_table (
        id serial NOT NULL,
        created_at timestamptz NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE(created_at);

      CREATE TABLE #{identifier} PARTITION OF public._test_partitioned_table
      FOR VALUES FROM ('2020-01-01') to ('2020-02-01');
    SQL
  end

  def find(identifier)
    described_class.by_identifier(identifier)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:postgres_partitioned_table).with_primary_key('identifier').with_foreign_key('parent_identifier') }
  end

  it_behaves_like 'a postgres model'

  describe '.for_parent_table' do
    let(:second_name) { '_test_partition_02' }

    before do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE #{schema}.#{second_name} PARTITION OF public._test_partitioned_table
        FOR VALUES FROM ('2020-02-01') to ('2020-03-01');

        CREATE TABLE #{schema}._test_other_table (
          id serial NOT NULL,
          created_at timestamptz NOT NULL,
          PRIMARY KEY (id, created_at)
        ) PARTITION BY RANGE(created_at);

        CREATE TABLE #{schema}._test_other_partition_01 PARTITION OF #{schema}._test_other_table
        FOR VALUES FROM ('2020-01-01') to ('2020-02-01');
      SQL
    end

    it 'returns partitions for the parent table in the current schema' do
      partitions = described_class.for_parent_table('_test_partitioned_table')

      expect(partitions.count).to eq(2)
      expect(partitions.pluck(:name)).to eq([name, second_name])
    end

    it 'does not return partitions for tables not in the current schema' do
      expect(described_class.for_parent_table('_test_other_table').count).to eq(0)
    end
  end

  describe '#parent_identifier' do
    it 'returns the parent table identifier' do
      expect(find(identifier).parent_identifier).to eq('public._test_partitioned_table')
    end
  end

  describe '#condition' do
    it 'returns the condition for the partitioned values' do
      expect(find(identifier).condition).to eq("FOR VALUES FROM ('2020-01-01 00:00:00+00') TO ('2020-02-01 00:00:00+00')")
    end
  end
end
