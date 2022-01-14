# frozen_string_literal: true

module Ci
  module Queue
    class PendingBuildsStrategy
      attr_reader :runner

      def initialize(runner)
        @runner = runner
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def builds_for_shared_runner
        shared_builds = builds_available_for_shared_runners

        builds_ordered_for_shared_runners(shared_builds)
      end

      def builds_for_group_runner
        return new_builds.none if runner.namespace_ids.empty?

        new_builds.where('ci_pending_builds.namespace_traversal_ids && ARRAY[?]::int[]', runner.namespace_ids)
      end

      def builds_matching_tag_ids(relation, ids)
        if use_denormalized_data_strategy?
          relation.for_tags(runner.tags_ids)
        else
          relation.merge(CommitStatus.matches_tag_ids(ids, table: 'ci_pending_builds', column: 'build_id'))
        end
      end

      def builds_with_any_tags(relation)
        if use_denormalized_data_strategy?
          relation.where('cardinality(tag_ids) > 0')
        else
          relation.merge(CommitStatus.with_any_tags(table: 'ci_pending_builds', column: 'build_id'))
        end
      end

      def order(relation)
        relation.order('build_id ASC')
      end

      def new_builds
        ::Ci::PendingBuild.all
      end

      def build_ids(relation)
        relation.pluck(:build_id)
      end

      def use_denormalized_data_strategy?
        ::Feature.enabled?(:ci_queuing_use_denormalized_data_strategy, default_enabled: :yaml)
      end

      private

      def builds_available_for_shared_runners
        if use_denormalized_data_strategy?
          new_builds.with_instance_runners
        else
          new_builds
            # don't run projects which have not enabled shared runners and builds
            .joins('INNER JOIN projects ON ci_pending_builds.project_id = projects.id')
            .where(projects: { shared_runners_enabled: true, pending_delete: false })
            .joins('LEFT JOIN project_features ON ci_pending_builds.project_id = project_features.project_id')
            .where('project_features.builds_access_level IS NULL or project_features.builds_access_level > 0')
        end
      end

      def builds_ordered_for_shared_runners(relation)
        if Feature.enabled?(:ci_queueing_disaster_recovery_disable_fair_scheduling, runner, type: :ops, default_enabled: :yaml)
          # if disaster recovery is enabled, we fallback to FIFO scheduling
          relation.order('ci_pending_builds.build_id ASC')
        else
          # Implement fair scheduling
          # this returns builds that are ordered by number of running builds
          # we prefer projects that don't use shared runners at all
          relation
            .with(running_builds_for_shared_runners_cte.to_arel)
            .joins("LEFT JOIN project_builds ON ci_pending_builds.project_id = project_builds.project_id")
            .order(Arel.sql('COALESCE(project_builds.running_builds, 0) ASC'), 'ci_pending_builds.build_id ASC')
        end
      end

      def running_builds_for_shared_runners_cte
        running_builds = ::Ci::RunningBuild
          .instance_type
          .group(:project_id)
          .select(:project_id, 'COUNT(*) AS running_builds')

        ::Gitlab::SQL::CTE
          .new(:project_builds, running_builds, materialized: true)
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end

Ci::Queue::PendingBuildsStrategy.prepend_mod_with('Ci::Queue::PendingBuildsStrategy')
