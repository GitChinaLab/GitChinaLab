# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresIndex do
  let(:schema) { 'public' }
  let(:name) { 'foo_idx' }
  let(:identifier) { "#{schema}.#{name}" }

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE INDEX #{name} ON public.users (name);
      CREATE UNIQUE INDEX bar_key ON public.users (id);

      CREATE TABLE example_table (id serial primary key);
    SQL
  end

  def find(name)
    described_class.by_identifier(name)
  end

  it_behaves_like 'a postgres model'

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe '.reindexing_support' do
    it 'only non partitioned indexes' do
      expect(described_class.reindexing_support).to all(have_attributes(partitioned: false))
    end

    it 'only indexes that dont serve an exclusion constraint' do
      expect(described_class.reindexing_support).to all(have_attributes(exclusion: false))
    end

    it 'only non-expression indexes' do
      expect(described_class.reindexing_support).to all(have_attributes(expression: false))
    end

    it 'only btree and gist indexes' do
      types = described_class.reindexing_support.map(&:type).uniq

      expect(types & %w(btree gist)).to eq(types)
    end

    context 'with leftover indexes' do
      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE INDEX foobar_ccnew ON users (id);
          CREATE INDEX foobar_ccnew1 ON users (id);
        SQL
      end

      subject { described_class.reindexing_support.map(&:name) }

      it 'excludes temporary indexes from reindexing' do
        expect(subject).not_to include('foobar_ccnew')
        expect(subject).not_to include('foobar_ccnew1')
      end
    end
  end

  describe '.reindexing_leftovers' do
    subject { described_class.reindexing_leftovers }

    before do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE INDEX foobar_ccnew ON users (id);
        CREATE INDEX foobar_ccnew1 ON users (id);
      SQL
    end

    it 'retrieves leftover indexes matching the /_ccnew[0-9]*$/ pattern' do
      expect(subject.map(&:name)).to eq(%w(foobar_ccnew foobar_ccnew1))
    end
  end

  describe '.not_match' do
    it 'excludes indexes matching the given regex' do
      expect(described_class.not_match('^bar_k').map(&:name)).to all(match(/^(?!bar_k).*/))
    end

    it 'matches indexes without this prefix regex' do
      expect(described_class.not_match('^bar_k')).not_to be_empty
    end
  end

  describe '#bloat_size' do
    subject { build(:postgres_index, bloat_estimate: bloat_estimate) }

    let(:bloat_estimate) { build(:postgres_index_bloat_estimate) }
    let(:bloat_size) { double }

    it 'returns the bloat size from the estimate' do
      expect(bloat_estimate).to receive(:bloat_size).and_return(bloat_size)

      expect(subject.bloat_size).to eq(bloat_size)
    end

    context 'without a bloat estimate available' do
      let(:bloat_estimate) { nil }

      it 'returns 0' do
        expect(subject.bloat_size).to eq(0)
      end
    end
  end

  describe '#relative_bloat_level' do
    subject { build(:postgres_index, bloat_estimate: bloat_estimate, ondisk_size_bytes: 1024) }

    let(:bloat_estimate) { build(:postgres_index_bloat_estimate, bloat_size: 256) }

    it 'calculates the relative bloat level' do
      expect(subject.relative_bloat_level).to eq(0.25)
    end
  end

  describe '#reset' do
    subject { index.reset }

    let(:index) { described_class.by_identifier(identifier) }

    it 'calls #reload' do
      expect(index).to receive(:reload).once.and_call_original

      subject
    end

    it 'resets the bloat estimation' do
      expect(index).to receive(:clear_memoization).with(:bloat_size).and_call_original

      subject
    end
  end

  describe '#unique?' do
    it 'returns true for a unique index' do
      expect(find('public.bar_key')).to be_unique
    end

    it 'returns false for a regular, non-unique index' do
      expect(find('public.foo_idx')).not_to be_unique
    end

    it 'returns true for a primary key index' do
      expect(find('public.example_table_pkey')).to be_unique
    end
  end

  describe '#valid_index?' do
    it 'returns true if the index is invalid' do
      expect(find(identifier)).to be_valid_index
    end

    it 'returns false if the index is marked as invalid' do
      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE pg_index SET indisvalid=false
        FROM pg_class
        WHERE pg_class.relname = 'foo_idx' AND pg_index.indexrelid = pg_class.oid
      SQL

      expect(find(identifier)).not_to be_valid_index
    end
  end

  describe '#definition' do
    it 'returns the index definition' do
      expect(find(identifier).definition).to eq('CREATE INDEX foo_idx ON public.users USING btree (name)')
    end
  end
end
