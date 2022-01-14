# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reflection do
  let(:database) { described_class.new(ApplicationRecord) }

  describe '#username' do
    context 'when a username is set' do
      it 'returns the username' do
        allow(database).to receive(:config).and_return(username: 'bob')

        expect(database.username).to eq('bob')
      end
    end

    context 'when a username is not set' do
      it 'returns the value of the USER environment variable' do
        allow(database).to receive(:config).and_return(username: nil)
        allow(ENV).to receive(:[]).with('USER').and_return('bob')

        expect(database.username).to eq('bob')
      end
    end
  end

  describe '#database_name' do
    it 'returns the name of the database' do
      allow(database).to receive(:config).and_return(database: 'test')

      expect(database.database_name).to eq('test')
    end
  end

  describe '#adapter_name' do
    it 'returns the database adapter name' do
      allow(database).to receive(:config).and_return(adapter: 'test')

      expect(database.adapter_name).to eq('test')
    end
  end

  describe '#human_adapter_name' do
    context 'when the adapter is PostgreSQL' do
      it 'returns PostgreSQL' do
        allow(database).to receive(:config).and_return(adapter: 'postgresql')

        expect(database.human_adapter_name).to eq('PostgreSQL')
      end
    end

    context 'when the adapter is not PostgreSQL' do
      it 'returns Unknown' do
        allow(database).to receive(:config).and_return(adapter: 'kittens')

        expect(database.human_adapter_name).to eq('Unknown')
      end
    end
  end

  describe '#postgresql?' do
    context 'when using PostgreSQL' do
      it 'returns true' do
        allow(database).to receive(:adapter_name).and_return('PostgreSQL')

        expect(database.postgresql?).to eq(true)
      end
    end

    context 'when not using PostgreSQL' do
      it 'returns false' do
        allow(database).to receive(:adapter_name).and_return('MySQL')

        expect(database.postgresql?).to eq(false)
      end
    end
  end

  describe '#db_read_only?' do
    it 'detects a read-only database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "t" }])

      expect(database.db_read_only?).to be_truthy
    end

    it 'detects a read-only database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => true }])

      expect(database.db_read_only?).to be_truthy
    end

    it 'detects a read-write database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "f" }])

      expect(database.db_read_only?).to be_falsey
    end

    it 'detects a read-write database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => false }])

      expect(database.db_read_only?).to be_falsey
    end
  end

  describe '#db_read_write?' do
    it 'detects a read-only database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "t" }])

      expect(database.db_read_write?).to eq(false)
    end

    it 'detects a read-only database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => true }])

      expect(database.db_read_write?).to eq(false)
    end

    it 'detects a read-write database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => "f" }])

      expect(database.db_read_write?).to eq(true)
    end

    it 'detects a read-write database' do
      allow(database.model.connection)
        .to receive(:execute)
        .with('SELECT pg_is_in_recovery()')
        .and_return([{ "pg_is_in_recovery" => false }])

      expect(database.db_read_write?).to eq(true)
    end
  end

  describe '#version' do
    around do |example|
      database.instance_variable_set(:@version, nil)
      example.run
      database.instance_variable_set(:@version, nil)
    end

    context "on postgresql" do
      it "extracts the version number" do
        allow(database)
          .to receive(:database_version)
          .and_return("PostgreSQL 9.4.4 on x86_64-apple-darwin14.3.0")

        expect(database.version).to eq '9.4.4'
      end
    end

    it 'memoizes the result' do
      count = ActiveRecord::QueryRecorder
        .new { 2.times { database.version } }
        .count

      expect(count).to eq(1)
    end
  end

  describe '#postgresql_minimum_supported_version?' do
    it 'returns false when using PostgreSQL 10' do
      allow(database).to receive(:version).and_return('10')

      expect(database.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns false when using PostgreSQL 11' do
      allow(database).to receive(:version).and_return('11')

      expect(database.postgresql_minimum_supported_version?).to eq(false)
    end

    it 'returns true when using PostgreSQL 12' do
      allow(database).to receive(:version).and_return('12')

      expect(database.postgresql_minimum_supported_version?).to eq(true)
    end
  end

  describe '#cached_column_exists?' do
    it 'only retrieves the data from the schema cache' do
      database = described_class.new(Project)
      queries = ActiveRecord::QueryRecorder.new do
        2.times do
          expect(database.cached_column_exists?(:id)).to be_truthy
          expect(database.cached_column_exists?(:bogus_column)).to be_falsey
        end
      end

      expect(queries.count).to eq(0)
    end
  end

  describe '#cached_table_exists?' do
    it 'only retrieves the data from the schema cache' do
      dummy = Class.new(ActiveRecord::Base) do
        self.table_name = 'bogus_table_name'
      end

      queries = ActiveRecord::QueryRecorder.new do
        2.times do
          expect(described_class.new(Project).cached_table_exists?).to be_truthy
          expect(described_class.new(dummy).cached_table_exists?).to be_falsey
        end
      end

      expect(queries.count).to eq(0)
    end

    it 'returns false when database does not exist' do
      database = described_class.new(Project)

      expect(database.model).to receive(:connection) do
        raise ActiveRecord::NoDatabaseError, 'broken'
      end

      expect(database.cached_table_exists?).to be(false)
    end
  end

  describe '#exists?' do
    it 'returns true if the database exists' do
      expect(database.exists?).to be(true)
    end

    it "returns false if the database doesn't exist" do
      expect(database.model.connection.schema_cache)
        .to receive(:database_version)
        .and_raise(ActiveRecord::NoDatabaseError)

      expect(database.exists?).to be(false)
    end
  end

  describe '#system_id' do
    it 'returns the PostgreSQL system identifier' do
      expect(database.system_id).to be_an_instance_of(Integer)
    end
  end

  describe '#config' do
    it 'returns a HashWithIndifferentAccess' do
      expect(database.config)
        .to be_an_instance_of(HashWithIndifferentAccess)
    end

    it 'returns a default pool size' do
      expect(database.config)
        .to include(pool: Gitlab::Database.default_pool_size)
    end

    it 'does not cache its results' do
      a = database.config
      b = database.config

      expect(a).not_to equal(b)
    end
  end
end
