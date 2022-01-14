# frozen_string_literal: true

class Projects::GoogleCloudController < Projects::GoogleCloud::BaseController
  def index
    @js_data = {
      screen: 'home',
      serviceAccounts: GoogleCloud::ServiceAccountsService.new(project).find_for_project,
      createServiceAccountUrl: project_google_cloud_service_accounts_path(project),
      emptyIllustrationUrl: ActionController::Base.helpers.image_path('illustrations/pipelines_empty.svg')
    }.to_json
  end
end
