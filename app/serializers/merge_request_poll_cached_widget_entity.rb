# frozen_string_literal: true

class MergeRequestPollCachedWidgetEntity < IssuableEntity
  include MergeRequestMetricsHelper

  expose :auto_merge_enabled
  expose :state
  expose :merged_commit_sha
  expose :short_merged_commit_sha
  expose :merge_error
  expose :public_merge_status, as: :merge_status
  expose :merge_user_id
  expose :source_branch
  expose :source_project_id
  expose :target_branch
  expose :target_branch_sha
  expose :target_project_id
  expose :squash
  expose :rebase_in_progress?, as: :rebase_in_progress
  expose :default_squash_commit_message
  expose :commits_count
  expose :merge_ongoing?, as: :merge_ongoing
  expose :work_in_progress?, as: :work_in_progress
  expose :cannot_be_merged?, as: :has_conflicts
  expose :can_be_merged?, as: :can_be_merged
  expose :remove_source_branch?, as: :remove_source_branch
  expose :source_branch_exists?, as: :source_branch_exists
  expose :branch_missing?, as: :branch_missing

  expose :commits_without_merge_commits, using: MergeRequestWidgetCommitEntity do |merge_request|
    merge_request.recent_commits.without_merge_commits
  end

  expose :diff_head_sha do |merge_request|
    merge_request.diff_head_sha.presence
  end
  expose :metrics do |merge_request|
    metrics = build_metrics(merge_request)

    MergeRequestMetricsEntity.new(metrics).as_json
  end

  expose :diverged_commits_count do |merge_request|
    if merge_request.open? && merge_request.diverged_from_target_branch?
      merge_request.diverged_commits_count
    else
      0
    end
  end

  expose :actual_head_pipeline, as: :pipeline, if: -> (mr, _) { presenter(mr).can_read_pipeline? } do |merge_request, options|
    MergeRequests::PipelineEntity.represent(merge_request.actual_head_pipeline, options)
  end

  expose :merge_pipeline, if: ->(mr, _) { mr.merged? && can?(request.current_user, :read_pipeline, mr.target_project) } do |merge_request, options|
    MergeRequests::PipelineEntity.represent(merge_request.merge_pipeline, options)
  end

  # Paths
  #
  expose :target_branch_commits_path do |merge_request|
    presenter(merge_request).target_branch_commits_path
  end

  expose :merge_request_widget_path do |merge_request|
    widget_project_json_merge_request_path(merge_request.target_project, merge_request, format: :json)
  end

  expose :target_branch_tree_path do |merge_request|
    presenter(merge_request).target_branch_tree_path
  end

  expose :merged_commit_path do |merge_request|
    if sha = merge_request.merged_commit_sha
      project_commit_path(merge_request.project, sha)
    end
  end

  expose :source_branch_path do |merge_request|
    presenter(merge_request).source_branch_path
  end

  expose :source_branch_with_namespace_link do |merge_request|
    presenter(merge_request).source_branch_with_namespace_link
  end

  expose :diffs_path do |merge_request|
    diffs_project_merge_request_path(merge_request.project, merge_request)
  end

  expose :squash_enabled_by_default do |merge_request|
    presenter(merge_request).project.squash_enabled_by_default?
  end

  expose :squash_readonly do |merge_request|
    presenter(merge_request).project.squash_readonly?
  end

  expose :squash_on_merge do |merge_request|
    presenter(merge_request).squash_on_merge?
  end

  expose :api_approvals_path do |merge_request|
    presenter(merge_request).api_approvals_path
  end

  expose :api_approve_path do |merge_request|
    presenter(merge_request).api_approve_path
  end

  expose :api_unapprove_path do |merge_request|
    presenter(merge_request).api_unapprove_path
  end

  expose :test_reports_path do |merge_request|
    if merge_request.has_test_reports?
      test_reports_project_merge_request_path(merge_request.project, merge_request, format: :json)
    end
  end

  expose :accessibility_report_path do |merge_request|
    if merge_request.has_accessibility_reports?
      accessibility_reports_project_merge_request_path(merge_request.project, merge_request, format: :json)
    end
  end

  expose :codequality_reports_path do |merge_request|
    if merge_request.has_codequality_reports?
      codequality_reports_project_merge_request_path(merge_request.project, merge_request, format: :json)
    end
  end

  expose :terraform_reports_path do |merge_request|
    if merge_request.has_terraform_reports?
      terraform_reports_project_merge_request_path(merge_request.project, merge_request, format: :json)
    end
  end

  expose :exposed_artifacts_path do |merge_request|
    if merge_request.has_exposed_artifacts?
      exposed_artifacts_project_merge_request_path(merge_request.project, merge_request, format: :json)
    end
  end

  expose :blob_path do
    expose :head_path, if: -> (mr, _) { mr.source_branch_sha } do |merge_request|
      project_blob_path(merge_request.project, merge_request.source_branch_sha)
    end

    expose :base_path, if: -> (mr, _) { mr.diff_base_sha } do |merge_request|
      project_blob_path(merge_request.project, merge_request.diff_base_sha)
    end
  end

  private

  delegate :current_user, to: :request

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: current_user) # rubocop: disable CodeReuse/Presenter
  end
end

MergeRequestPollCachedWidgetEntity.prepend_mod_with('MergeRequestPollCachedWidgetEntity')
