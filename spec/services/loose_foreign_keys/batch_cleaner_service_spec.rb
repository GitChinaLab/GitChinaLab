# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::BatchCleanerService do
  include MigrationsHelpers

  def create_table_structure
    migration = ActiveRecord::Migration.new.extend(Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers)

    migration.create_table :_test_loose_fk_parent_table

    migration.create_table :_test_loose_fk_child_table_1 do |t|
      t.bigint :parent_id
    end

    migration.create_table :_test_loose_fk_child_table_2 do |t|
      t.bigint :parent_id_with_different_column
    end

    migration.track_record_deletions(:_test_loose_fk_parent_table)
  end

  let(:loose_foreign_key_definitions) do
    [
      ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
        '_test_loose_fk_child_table_1',
        '_test_loose_fk_parent_table',
        {
          column: 'parent_id',
          on_delete: :async_delete,
          gitlab_schema: :gitlab_main
        }
      ),
      ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
        '_test_loose_fk_child_table_2',
        '_test_loose_fk_parent_table',
        {
          column: 'parent_id_with_different_column',
          on_delete: :async_nullify,
          gitlab_schema: :gitlab_main
        }
      )
    ]
  end

  let(:loose_fk_parent_table) { table(:_test_loose_fk_parent_table) }
  let(:loose_fk_child_table_1) { table(:_test_loose_fk_child_table_1) }
  let(:loose_fk_child_table_2) { table(:_test_loose_fk_child_table_2) }
  let(:parent_record_1) { loose_fk_parent_table.create! }
  let(:other_parent_record) { loose_fk_parent_table.create! }

  before(:all) do
    create_table_structure
  end

  before do
    parent_record_1

    loose_fk_child_table_1.create!(parent_id: parent_record_1.id)
    loose_fk_child_table_1.create!(parent_id: parent_record_1.id)

    # these will not be deleted
    loose_fk_child_table_1.create!(parent_id: other_parent_record.id)
    loose_fk_child_table_1.create!(parent_id: other_parent_record.id)

    loose_fk_child_table_2.create!(parent_id_with_different_column: parent_record_1.id)
    loose_fk_child_table_2.create!(parent_id_with_different_column: parent_record_1.id)

    # these will not be deleted
    loose_fk_child_table_2.create!(parent_id_with_different_column: other_parent_record.id)
    loose_fk_child_table_2.create!(parent_id_with_different_column: other_parent_record.id)
  end

  after(:all) do
    migration = ActiveRecord::Migration.new
    migration.drop_table :_test_loose_fk_parent_table
    migration.drop_table :_test_loose_fk_child_table_1
    migration.drop_table :_test_loose_fk_child_table_2
  end

  context 'when parent records are deleted' do
    let(:deleted_records_counter) { Gitlab::Metrics.registry.get(:loose_foreign_key_processed_deleted_records) }

    before do
      parent_record_1.delete

      expect(loose_fk_child_table_1.count).to eq(4)
      expect(loose_fk_child_table_2.count).to eq(4)

      described_class.new(parent_table: '_test_loose_fk_parent_table',
                          loose_foreign_key_definitions: loose_foreign_key_definitions,
                          deleted_parent_records: LooseForeignKeys::DeletedRecord.load_batch_for_table('public._test_loose_fk_parent_table', 100)
                         ).execute
    end

    it 'cleans up the child records' do
      expect(loose_fk_child_table_1.where(parent_id: parent_record_1.id)).to be_empty
      expect(loose_fk_child_table_2.where(parent_id_with_different_column: nil).count).to eq(2)
    end

    it 'cleans up the pending parent DeletedRecord' do
      expect(LooseForeignKeys::DeletedRecord.status_pending.count).to eq(0)
      expect(LooseForeignKeys::DeletedRecord.status_processed.count).to eq(1)
    end

    it 'records the DeletedRecord status updates', :prometheus do
      counter = Gitlab::Metrics.registry.get(:loose_foreign_key_processed_deleted_records)

      expect(counter.get(table: loose_fk_parent_table.table_name, db_config_name: 'main')).to eq(1)
    end

    it 'does not delete unrelated records' do
      expect(loose_fk_child_table_1.where(parent_id: other_parent_record.id).count).to eq(2)
      expect(loose_fk_child_table_2.where(parent_id_with_different_column: other_parent_record.id).count).to eq(2)
    end
  end
end
