# frozen_string_literal: true

class PagesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  feature_category :pages
  loggable_arguments 0, 1
  worker_resource_boundary :cpu

  def perform(action, *arg)
    send(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
  end

  def deploy(build_id)
    build = Ci::Build.find_by_id(build_id)
    update_contents = Projects::UpdatePagesService.new(build.project, build).execute
    if update_contents[:status] == :success
      Projects::UpdatePagesConfigurationService.new(build.project).execute
    end
  end

  def remove(namespace_path, project_path)
    full_path = File.join(Settings.pages.path, namespace_path, project_path)
    FileUtils.rm_r(full_path, force: true)
  end
end
