# frozen_string_literal: true

module Projects::TerraformHelper
  def js_terraform_list_data(current_user, project)
    {
      empty_state_image: image_path('illustrations/empty-state/empty-serverless-lg.svg'),
      project_path: project.full_path,
      terraform_admin: current_user&.can?(:admin_terraform_state, project),
      access_tokens_path: profile_personal_access_tokens_path,
      username: current_user&.username,
      terraform_api_url: "#{Settings.gitlab.url}/api/v4/projects/#{project.id}/terraform/state"
    }
  end
end
