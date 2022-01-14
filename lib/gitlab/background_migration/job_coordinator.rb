# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class responsible for executing background migrations based on the given database.
    #
    # Chooses the correct worker class when selecting jobs from the queue based on the
    # convention of how the queues and worker classes are setup for each database.
    #
    # Also provides a database connection to the correct tracking database.
    class JobCoordinator # rubocop:disable Metrics/ClassLength
      class << self
        def worker_classes
          @worker_classes ||= [
            BackgroundMigrationWorker
          ].freeze
        end

        def worker_for_tracking_database
          @worker_for_tracking_database ||= worker_classes
            .index_by(&:tracking_database)
            .with_indifferent_access
            .freeze
        end

        def for_tracking_database(tracking_database)
          worker_class = worker_for_tracking_database[tracking_database]

          if worker_class.nil?
            raise ArgumentError, "tracking_database must be one of [#{worker_for_tracking_database.keys.join(', ')}]"
          end

          new(worker_class)
        end
      end

      attr_reader :worker_class

      def queue
        @queue ||= worker_class.sidekiq_options['queue']
      end

      def with_shared_connection(&block)
        Gitlab::Database::SharedModel.using_connection(connection, &block)
      end

      def steal(steal_class, retry_dead_jobs: false)
        with_shared_connection do
          queues = [
            Sidekiq::ScheduledSet.new,
            Sidekiq::Queue.new(self.queue)
          ]

          if retry_dead_jobs
            queues << Sidekiq::RetrySet.new
            queues << Sidekiq::DeadSet.new
          end

          queues.each do |queue|
            queue.each do |job|
              migration_class, migration_args = job.args

              next unless job.klass == worker_class.name
              next unless migration_class == steal_class
              next if block_given? && !(yield job)

              begin
                perform(migration_class, migration_args) if job.delete
              rescue Exception # rubocop:disable Lint/RescueException
                worker_class # enqueue this migration again
                  .perform_async(migration_class, migration_args)

                raise
              end
            end
          end
        end
      end

      def perform(class_name, arguments)
        with_shared_connection do
          migration_class_for(class_name).new.perform(*arguments)
        end
      end

      def remaining
        enqueued = Sidekiq::Queue.new(self.queue)
        scheduled = Sidekiq::ScheduledSet.new

        [enqueued, scheduled].sum do |set|
          set.count do |job|
            job.klass == worker_class.name
          end
        end
      end

      def exists?(migration_class, additional_queues = [])
        enqueued = Sidekiq::Queue.new(self.queue)
        scheduled = Sidekiq::ScheduledSet.new

        enqueued_job?([enqueued, scheduled], migration_class)
      end

      def dead_jobs?(migration_class)
        dead_set = Sidekiq::DeadSet.new

        enqueued_job?([dead_set], migration_class)
      end

      def retrying_jobs?(migration_class)
        retry_set = Sidekiq::RetrySet.new

        enqueued_job?([retry_set], migration_class)
      end

      def migration_class_for(class_name)
        Gitlab::BackgroundMigration.const_get(class_name, false)
      end

      def enqueued_job?(queues, migration_class)
        queues.any? do |queue|
          queue.any? do |job|
            job.klass == worker_class.name && job.args.first == migration_class
          end
        end
      end

      private

      def initialize(worker_class)
        @worker_class = worker_class
      end

      def connection
        @connection ||= Gitlab::Database
          .database_base_models
          .fetch(worker_class.tracking_database, Gitlab::Database::PRIMARY_DATABASE_NAME)
          .connection
      end
    end
  end
end
