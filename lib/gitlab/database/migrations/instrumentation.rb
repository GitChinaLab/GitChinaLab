# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class Instrumentation
        STATS_FILENAME = 'migration-stats.json'

        attr_reader :observations

        def initialize(result_dir:, observer_classes: ::Gitlab::Database::Migrations::Observers.all_observers)
          @observer_classes = observer_classes
          @observations = []
          @result_dir = result_dir
        end

        def observe(version:, name:, connection:, &block)
          observation = Observation.new(version, name)
          observation.success = true

          observers = observer_classes.map { |c| c.new(observation, @result_dir, connection) }

          exception = nil

          on_each_observer(observers) { |observer| observer.before }

          observation.walltime = Benchmark.realtime do
            yield
          rescue StandardError => e
            exception = e
            observation.success = false
          end

          on_each_observer(observers) { |observer| observer.after }
          on_each_observer(observers) { |observer| observer.record }

          record_observation(observation)

          raise exception if exception

          observation
        end

        private

        attr_reader :observer_classes

        def record_observation(observation)
          @observations << observation
        end

        def on_each_observer(observers, &block)
          observers.each do |observer|
            yield observer
          rescue StandardError => e
            Gitlab::AppLogger.error("Migration observer #{observer.class} failed with: #{e}")
          end
        end
      end
    end
  end
end
