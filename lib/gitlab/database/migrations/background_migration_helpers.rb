# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module BackgroundMigrationHelpers
        BATCH_SIZE = 1_000 # Number of rows to process per job
        JOB_BUFFER_SIZE = 1_000 # Number of jobs to bulk queue at a time

        # Queues background migration jobs for an entire table in batches.
        # The default batching column used is the standard primary key `id`.
        # Each job is scheduled with a `delay_interval` in between.
        # If you use a small interval, then some jobs may run at the same time.
        #
        # model_class - The table or relation being iterated over
        # job_class_name - The background migration job class as a string
        # delay_interval - The duration between each job's scheduled time (must respond to `to_f`)
        # batch_size - The maximum number of rows per job
        # other_arguments - Other arguments to send to the job
        # track_jobs - When this flag is set, creates a record in the background_migration_jobs table for each job that
        # is scheduled to be run. These records can be used to trace execution of the background job, but there is no
        # builtin support to manage that automatically at this time. You should only set this flag if you are aware of
        # how it works, and intend to manually cleanup the database records in your background job.
        # primary_column_name - The name of the primary key column if the primary key is not `id`
        #
        # *Returns the final migration delay*
        #
        # Example:
        #
        #     class Route < ActiveRecord::Base
        #       include EachBatch
        #       self.table_name = 'routes'
        #     end
        #
        #     queue_background_migration_jobs_by_range_at_intervals(Route, 'ProcessRoutes', 1.minute)
        #
        # Where the model_class includes EachBatch, and the background migration exists:
        #
        #     class Gitlab::BackgroundMigration::ProcessRoutes
        #       def perform(start_id, end_id)
        #         # do something
        #       end
        #     end
        def queue_background_migration_jobs_by_range_at_intervals(model_class, job_class_name, delay_interval, batch_size: BATCH_SIZE, other_job_arguments: [], initial_delay: 0, track_jobs: false, primary_column_name: :id)
          raise "#{model_class} does not have an ID column of #{primary_column_name} to use for batch ranges" unless model_class.column_names.include?(primary_column_name.to_s)
          raise "#{primary_column_name} is not an integer column" unless model_class.columns_hash[primary_column_name.to_s].type == :integer

          # To not overload the worker too much we enforce a minimum interval both
          # when scheduling and performing jobs.
          if delay_interval < BackgroundMigrationWorker.minimum_interval
            delay_interval = BackgroundMigrationWorker.minimum_interval
          end

          final_delay = 0
          batch_counter = 0

          model_class.each_batch(of: batch_size, column: primary_column_name) do |relation, index|
            max = relation.arel_table[primary_column_name].maximum
            min = relation.arel_table[primary_column_name].minimum

            start_id, end_id = relation.pluck(min, max).first

            # `BackgroundMigrationWorker.bulk_perform_in` schedules all jobs for
            # the same time, which is not helpful in most cases where we wish to
            # spread the work over time.
            final_delay = initial_delay + delay_interval * index
            full_job_arguments = [start_id, end_id] + other_job_arguments

            track_in_database(job_class_name, full_job_arguments) if track_jobs
            migrate_in(final_delay, job_class_name, full_job_arguments)

            batch_counter += 1
          end

          duration = initial_delay + delay_interval * batch_counter
          say <<~SAY
            Scheduled #{batch_counter} #{job_class_name} jobs with a maximum of #{batch_size} records per batch and an interval of #{delay_interval} seconds.

            The migration is expected to take at least #{duration} seconds. Expect all jobs to have completed after #{Time.zone.now + duration}."
          SAY

          final_delay
        end

        # Requeue pending jobs previously queued with #queue_background_migration_jobs_by_range_at_intervals
        #
        # This method is useful to schedule jobs that had previously failed.
        # It can only be used if the previous background migration used job tracking like the queue_background_migration_jobs_by_range_at_intervals helper.
        #
        # job_class_name - The background migration job class as a string
        # delay_interval - The duration between each job's scheduled time
        # batch_size - The maximum number of jobs to fetch to memory from the database.
        def requeue_background_migration_jobs_by_range_at_intervals(job_class_name, delay_interval, batch_size: BATCH_SIZE, initial_delay: 0)
          # To not overload the worker too much we enforce a minimum interval both
          # when scheduling and performing jobs.
          delay_interval = [delay_interval, BackgroundMigrationWorker.minimum_interval].max

          final_delay = 0
          job_counter = 0

          jobs = Gitlab::Database::BackgroundMigrationJob.pending.where(class_name: job_class_name)
          jobs.each_batch(of: batch_size) do |job_batch|
            job_batch.each do |job|
              final_delay = initial_delay + delay_interval * job_counter

              migrate_in(final_delay, job_class_name, job.arguments)

              job_counter += 1
            end
          end

          duration = initial_delay + delay_interval * job_counter
          say <<~SAY
            Scheduled #{job_counter} #{job_class_name} jobs with an interval of #{delay_interval} seconds.

            The migration is expected to take at least #{duration} seconds. Expect all jobs to have completed after #{Time.zone.now + duration}."
          SAY

          duration
        end

        # Force a background migration to complete.
        #
        # WARNING: This method will block the caller and move the background migration from an
        # asynchronous migration to a synchronous migration.
        #
        # 1. Steal work from sidekiq and perform immediately (avoid duplicates generated by step 2).
        # 2. Process any pending tracked jobs.
        # 3. Steal work from sidekiq and perform immediately (clear anything left from step 2).
        # 4. Optionally remove job tracking information.
        #
        # This method does not garauntee that all jobs completed successfully.
        # It can only be used if the previous background migration used the queue_background_migration_jobs_by_range_at_intervals helper.
        def finalize_background_migration(class_name, delete_tracking_jobs: ['succeeded'])
          # Empty the sidekiq queue.
          Gitlab::BackgroundMigration.steal(class_name)

          # Process pending tracked jobs.
          jobs = Gitlab::Database::BackgroundMigrationJob.pending.for_migration_class(class_name)
          jobs.find_each do |job|
            BackgroundMigrationWorker.new.perform(job.class_name, job.arguments)
          end

          # Empty the sidekiq queue.
          Gitlab::BackgroundMigration.steal(class_name)

          # Delete job tracking rows.
          delete_job_tracking(class_name, status: delete_tracking_jobs) if delete_tracking_jobs
        end

        def perform_background_migration_inline?
          Rails.env.test? || Rails.env.development?
        end

        def migrate_async(*args)
          with_migration_context do
            BackgroundMigrationWorker.perform_async(*args)
          end
        end

        def migrate_in(*args)
          with_migration_context do
            BackgroundMigrationWorker.perform_in(*args)
          end
        end

        def bulk_migrate_in(*args)
          with_migration_context do
            BackgroundMigrationWorker.bulk_perform_in(*args)
          end
        end

        def bulk_migrate_async(*args)
          with_migration_context do
            BackgroundMigrationWorker.bulk_perform_async(*args)
          end
        end

        def with_migration_context(&block)
          Gitlab::ApplicationContext.with_context(caller_id: self.class.to_s, &block)
        end

        def delete_queued_jobs(class_name)
          Gitlab::BackgroundMigration.steal(class_name) do |job|
            job.delete

            false
          end
        end

        def delete_job_tracking(class_name, status: 'succeeded')
          status = Array(status).map { |s| Gitlab::Database::BackgroundMigrationJob.statuses[s] }
          jobs = Gitlab::Database::BackgroundMigrationJob.where(status: status).for_migration_class(class_name)
          jobs.each_batch { |batch| batch.delete_all }
        end

        private

        def track_in_database(class_name, arguments)
          Gitlab::Database::BackgroundMigrationJob.create!(class_name: class_name, arguments: arguments)
        end
      end
    end
  end
end
