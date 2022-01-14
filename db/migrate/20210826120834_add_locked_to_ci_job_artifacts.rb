# frozen_string_literal: true

class AddLockedToCiJobArtifacts < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'ci_job_artifacts'
  COLUMN_NAME = 'locked'

  def up
    with_lock_retries do
      add_column TABLE_NAME, COLUMN_NAME, :smallint, default: 2
    end
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, COLUMN_NAME
    end
  end
end
