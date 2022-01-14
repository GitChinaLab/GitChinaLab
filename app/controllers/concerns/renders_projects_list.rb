# frozen_string_literal: true

module RendersProjectsList
  def prepare_projects_for_rendering(projects)
    preload_max_member_access_for_collection(Project, projects)

    # Call the count methods on every project, so the BatchLoader would load them all at
    # once when the entities are rendered
    projects.each(&:forks_count)
    projects.each(&:open_issues_count)

    projects
  end
end
