# frozen_string_literal: true

class FinalizePushEventPayloadsBigintConversion3 < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'push_event_payloads'
  INDEX_NAME = 'index_push_event_payloads_on_event_id_convert_to_bigint'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'event_id',
      job_arguments: [["event_id"], ["event_id_convert_to_bigint"]]
    )

    return if already_swapped?

    swap_columns
  end

  def down
    swap_columns
  end

  private

  def already_swapped?
    push_event_payloads_columns = columns(TABLE_NAME)
    event_id = push_event_payloads_columns.find {|c| c.name == 'event_id'}
    event_id_convert_to_bigint = push_event_payloads_columns.find {|c| c.name == 'event_id_convert_to_bigint'}

    event_id.sql_type == 'bigint' && event_id_convert_to_bigint.sql_type == 'integer'
  end

  def swap_columns
    add_concurrent_index TABLE_NAME, :event_id_convert_to_bigint, unique: true, name: INDEX_NAME

    # Add a foreign key on `event_id_convert_to_bigint` before we swap the columns and drop the old FK (fk_36c74129da)
    add_concurrent_foreign_key TABLE_NAME, :events, column: :event_id_convert_to_bigint,
      on_delete: :cascade, reverse_lock_order: true

    with_lock_retries(raise_on_exhaustion: true) do
      # We'll need  ACCESS EXCLUSIVE lock on the related tables,
      # lets make sure it can be acquired from the start.
      # Lock order should be
      #   1. events
      #   2. push_event_payloads
      # in order to match the order in EventCreateService#create_push_event,
      # and avoid deadlocks.
      execute "LOCK TABLE events, #{TABLE_NAME}  IN ACCESS EXCLUSIVE MODE"

      # Swap column names
      temp_name = 'event_id_tmp'
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:event_id)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:event_id_convert_to_bigint)} TO #{quote_column_name(:event_id)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:event_id_convert_to_bigint)}"

      # We need to update the trigger function in order to make PostgreSQL to
      # regenerate the execution plan for it. This is to avoid type mismatch errors like
      # "type of parameter 15 (bigint) does not match that when preparing the plan (integer)"
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME, connection: connection).name(:event_id, :event_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      change_column_default TABLE_NAME, :event_id, nil
      change_column_default TABLE_NAME, :event_id_convert_to_bigint, 0

      # Swap PK constraint
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT push_event_payloads_pkey"
      rename_index TABLE_NAME, INDEX_NAME, 'push_event_payloads_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT push_event_payloads_pkey PRIMARY KEY USING INDEX push_event_payloads_pkey"

      # Drop original FK on the old int4 `event_id` (fk_36c74129da)
      remove_foreign_key TABLE_NAME, name: concurrent_foreign_key_name(TABLE_NAME, :event_id)
      # We swapped the columns but the FK for event_id is still using the old name for the event_id_convert_to_bigint column
      # So we have to also swap the FK name now that we dropped the other one with the same
      rename_constraint(
        TABLE_NAME,
        concurrent_foreign_key_name(TABLE_NAME, :event_id_convert_to_bigint),
        concurrent_foreign_key_name(TABLE_NAME, :event_id)
      )
    end
  end
end
