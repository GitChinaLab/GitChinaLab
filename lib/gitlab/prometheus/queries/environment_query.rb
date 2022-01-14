# frozen_string_literal: true

module Gitlab
  module Prometheus
    module Queries
      class EnvironmentQuery < BaseQuery
        # rubocop: disable CodeReuse/ActiveRecord
        def query(environment_id)
          ::Environment.find_by(id: environment_id).try do |environment|
            environment_slug = environment.slug
            timeframe_start = 8.hours.ago.to_f
            timeframe_end = Time.now.to_f

            memory_query = raw_memory_usage_query(environment_slug)
            cpu_query = raw_cpu_usage_query(environment_slug)

            {
              memory_values: client_query_range(memory_query, start_time: timeframe_start, end_time: timeframe_end),
              memory_current: client_query(memory_query, time: timeframe_end),
              cpu_values: client_query_range(cpu_query, start_time: timeframe_start, end_time: timeframe_end),
              cpu_current: client_query(cpu_query, time: timeframe_end)
            }
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def self.transform_reactive_result(result)
          result[:metrics] = result.delete :data
          result
        end
      end
    end
  end
end
