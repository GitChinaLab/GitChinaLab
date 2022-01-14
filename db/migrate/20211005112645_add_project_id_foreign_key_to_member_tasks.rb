# frozen_string_literal: true

class AddProjectIdForeignKeyToMemberTasks < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :member_tasks, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :member_tasks, column: :project_id
    end
  end
end
