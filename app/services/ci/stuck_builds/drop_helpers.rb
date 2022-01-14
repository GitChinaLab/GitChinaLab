# frozen_string_literal: true

module Ci
  module StuckBuilds
    module DropHelpers
      def drop(builds, failure_reason:)
        fetch(builds) do |build|
          drop_build :outdated, build, failure_reason
        end
      end

      def drop_stuck(builds, failure_reason:)
        fetch(builds) do |build|
          break unless build.stuck?

          drop_build :stuck, build, failure_reason
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def fetch(builds)
        loop do
          jobs = builds.includes(:tags, :runner, project: [:namespace, :route])
            .limit(100)
            .to_a

          break if jobs.empty?

          jobs.each do |job|
            Gitlab::ApplicationContext.with_context(project: job.project) { yield(job) }
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def drop_build(type, build, reason)
        Gitlab::AppLogger.info "#{self.class}: Dropping #{type} build #{build.id} for runner #{build.runner_id} (status: #{build.status}, failure_reason: #{reason})"
        Gitlab::OptimisticLocking.retry_lock(build, 3, name: 'stuck_ci_jobs_worker_drop_build') do |b|
          b.drop(reason)
        end
      rescue StandardError => ex
        build.doom!

        track_exception_for_build(ex, build)
      end

      def track_exception_for_build(ex, build)
        Gitlab::ErrorTracking.track_exception(ex,
            build_id: build.id,
            build_name: build.name,
            build_stage: build.stage,
            pipeline_id: build.pipeline_id,
            project_id: build.project_id
        )
      end
    end
  end
end
