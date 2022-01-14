# frozen_string_literal: true

module API
  class ProjectHooks < ::API::Base
    include PaginationParams

    before { authenticate! }
    before { authorize_admin_project }

    feature_category :integrations

    helpers do
      params :project_hook_properties do
        requires :url, type: String, desc: "The URL to send the request to"
        optional :push_events, type: Boolean, desc: "Trigger hook on push events"
        optional :issues_events, type: Boolean, desc: "Trigger hook on issues events"
        optional :confidential_issues_events, type: Boolean, desc: "Trigger hook on confidential issues events"
        optional :merge_requests_events, type: Boolean, desc: "Trigger hook on merge request events"
        optional :tag_push_events, type: Boolean, desc: "Trigger hook on tag push events"
        optional :note_events, type: Boolean, desc: "Trigger hook on note(comment) events"
        optional :confidential_note_events, type: Boolean, desc: "Trigger hook on confidential note(comment) events"
        optional :job_events, type: Boolean, desc: "Trigger hook on job events"
        optional :pipeline_events, type: Boolean, desc: "Trigger hook on pipeline events"
        optional :wiki_page_events, type: Boolean, desc: "Trigger hook on wiki events"
        optional :deployment_events, type: Boolean, desc: "Trigger hook on deployment events"
        optional :releases_events, type: Boolean, desc: "Trigger hook on release events"
        optional :enable_ssl_verification, type: Boolean, desc: "Do SSL verification when triggering the hook"
        optional :token, type: String, desc: "Secret token to validate received payloads; this will not be returned in the response"
        optional :push_events_branch_filter, type: String, desc: "Trigger hook on specified branch only"
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get project hooks' do
        success Entities::ProjectHook
      end
      params do
        use :pagination
      end
      get ":id/hooks" do
        present paginate(user_project.hooks), with: Entities::ProjectHook
      end

      desc 'Get a project hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of a project hook'
      end
      get ":id/hooks/:hook_id" do
        hook = user_project.hooks.find(params[:hook_id])
        present hook, with: Entities::ProjectHook
      end

      desc 'Add hook to project' do
        success Entities::ProjectHook
      end
      params do
        use :project_hook_properties
      end
      post ":id/hooks" do
        hook_params = declared_params(include_missing: false)

        hook = user_project.hooks.new(hook_params)

        if hook.save
          present hook, with: Entities::ProjectHook
        else
          error!("Invalid url given", 422) if hook.errors[:url].present?
          error!("Invalid branch filter given", 422) if hook.errors[:push_events_branch_filter].present?

          not_found!("Project hook #{hook.errors.messages}")
        end
      end

      desc 'Update an existing project hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: "The ID of the hook to update"
        use :project_hook_properties
      end
      put ":id/hooks/:hook_id" do
        hook = user_project.hooks.find(params.delete(:hook_id))

        update_params = declared_params(include_missing: false)

        if hook.update(update_params)
          present hook, with: Entities::ProjectHook
        else
          error!("Invalid url given", 422) if hook.errors[:url].present?
          error!("Invalid branch filter given", 422) if hook.errors[:push_events_branch_filter].present?

          not_found!("Project hook #{hook.errors.messages}")
        end
      end

      desc 'Deletes project hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook to delete'
      end
      delete ":id/hooks/:hook_id" do
        hook = user_project.hooks.find(params.delete(:hook_id))

        destroy_conditionally!(hook) do
          WebHooks::DestroyService.new(current_user).execute(hook)
        end
      end
    end
  end
end
