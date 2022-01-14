# frozen_string_literal: true

class TrackDeletionsInProjects < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    track_record_deletions(:projects)
  end

  def down
    untrack_record_deletions(:projects)
  end
end
