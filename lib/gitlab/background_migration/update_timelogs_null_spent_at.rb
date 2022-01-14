# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class to populate spent_at for timelogs
    class UpdateTimelogsNullSpentAt
      include Gitlab::Database::DynamicModelHelpers

      BATCH_SIZE = 100

      def perform(start_id, stop_id)
        define_batchable_model('timelogs').where(spent_at: nil, id: start_id..stop_id).each_batch(of: 100) do |subbatch|
          batch_start, batch_end = subbatch.pluck('min(id), max(id)').first

          update_timelogs(batch_start, batch_end)
        end
      end

      def update_timelogs(batch_start, batch_stop)
        execute(<<~SQL)
          UPDATE timelogs
          SET spent_at = created_at
          WHERE spent_at IS NULL
          AND timelogs.id BETWEEN #{batch_start} AND #{batch_stop};
        SQL
      end

      def execute(sql)
        @connection ||= ::ActiveRecord::Base.connection
        @connection.execute(sql)
      end
    end
  end
end
