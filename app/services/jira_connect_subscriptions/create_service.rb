# frozen_string_literal: true

module JiraConnectSubscriptions
  class CreateService < ::JiraConnectSubscriptions::BaseService
    include Gitlab::Utils::StrongMemoize
    MERGE_REQUEST_SYNC_BATCH_SIZE = 20
    MERGE_REQUEST_SYNC_BATCH_DELAY = 1.minute.freeze
    NOT_SITE_ADMIN = 'The Jira user is not a site administrator.'

    def execute
      return error(NOT_SITE_ADMIN, 403) unless can_administer_jira?

      unless namespace && can?(current_user, :create_jira_connect_subscription, namespace)
        return error('Invalid namespace. Please make sure you have sufficient permissions', 401)
      end

      create_subscription
    end

    private

    def can_administer_jira?
      @params[:jira_user]&.site_admin?
    end

    def create_subscription
      subscription = JiraConnectSubscription.new(installation: jira_connect_installation, namespace: namespace)

      if subscription.save
        schedule_sync_project_jobs

        success
      else
        error(subscription.errors.full_messages.join(', '), 422)
      end
    end

    def namespace
      strong_memoize(:namespace) do
        Namespace.find_by_full_path(params[:namespace_path])
      end
    end

    def schedule_sync_project_jobs
      namespace.all_projects.each_batch(of: MERGE_REQUEST_SYNC_BATCH_SIZE) do |projects, index|
        JiraConnect::SyncProjectWorker.bulk_perform_in_with_contexts(
          index * MERGE_REQUEST_SYNC_BATCH_DELAY,
          projects,
          arguments_proc: -> (project) { [project.id, Atlassian::JiraConnect::Client.generate_update_sequence_id] },
          context_proc: -> (project) { { project: project } }
        )
      end
    end
  end
end
