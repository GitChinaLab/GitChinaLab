# frozen_string_literal: true

module MergeRequests
  class AfterCreateService < MergeRequests::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(merge_request)
      prepare_for_mergeability(merge_request) if early_prepare_for_mergeability?(merge_request)
      prepare_merge_request(merge_request)
      mark_as_unchecked(merge_request) unless early_prepare_for_mergeability?(merge_request)
    end

    private

    def prepare_for_mergeability(merge_request)
      create_pipeline_for(merge_request, current_user)
      merge_request.update_head_pipeline
      mark_as_unchecked(merge_request)
    end

    def prepare_merge_request(merge_request)
      event_service.open_mr(merge_request, current_user)

      merge_request_activity_counter.track_create_mr_action(user: current_user)
      merge_request_activity_counter.track_mr_including_ci_config(user: current_user, merge_request: merge_request)

      notification_service.new_merge_request(merge_request, current_user)

      unless early_prepare_for_mergeability?(merge_request)
        create_pipeline_for(merge_request, current_user)
        merge_request.update_head_pipeline
      end

      merge_request.diffs(include_stats: false).write_cache
      merge_request.create_cross_references!(current_user)

      OnboardingProgressService.new(merge_request.target_project.namespace).execute(action: :merge_request_created)

      todo_service.new_merge_request(merge_request, current_user)
      merge_request.cache_merge_request_closes_issues!(current_user)

      Gitlab::UsageDataCounters::MergeRequestCounter.count(:create)
      link_lfs_objects(merge_request)

      delete_milestone_total_merge_requests_counter_cache(merge_request.milestone)
    end

    def link_lfs_objects(merge_request)
      LinkLfsObjectsService.new(project: merge_request.target_project).execute(merge_request)
    end

    def early_prepare_for_mergeability?(merge_request)
      strong_memoize("early_prepare_for_mergeability_#{merge_request.target_project_id}".to_sym) do
        Feature.enabled?(:early_prepare_for_mergeability, merge_request.target_project)
      end
    end

    def mark_as_unchecked(merge_request)
      merge_request.mark_as_unchecked if merge_request.preparing?
    end
  end
end

MergeRequests::AfterCreateService.prepend_mod_with('MergeRequests::AfterCreateService')
