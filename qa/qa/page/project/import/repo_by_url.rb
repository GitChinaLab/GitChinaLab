# frozen_string_literal: true

module QA
  module Page
    module Project
      module Import
        class RepoByURL < Page::Base
          view 'app/assets/javascripts/projects/new/components/new_project_url_select.vue' do
            element :select_namespace_dropdown
            element :select_namespace_dropdown_search_field
          end

          def import!(gitlab_repo_path, name)
            fill_git_repository_url_link(gitlab_repo_path)
            fill_project_name(name)
            choose_test_namespace
            click_create_button

            wait_for_success

            go_to_project(name)
          end

          private

          def fill_git_repository_url_link(gitlab_repo_path)
            fill_in 'project_import_url', with: gitlab_repo_path
          end

          def fill_project_name(name)
            fill_in 'project_name', with: name
          end

          def choose_test_namespace
            choose_namespace(Runtime::Namespace.path)
          end

          def choose_namespace(namespace)
            retry_on_exception do
              click_element :select_namespace_dropdown
              fill_element :select_namespace_dropdown_search_field, namespace
              click_button namespace
            end
          end

          def click_create_button
            find('.btn-confirm').click
          end

          def wait_for_success
            wait_until(max_duration: 60, sleep_interval: 5.0, reload: true, skip_finished_loading_check_on_refresh: true) do
              page.has_no_content?('Import in progress', wait: 3.0)
            end
          end

          def go_to_project(name)
            Page::Main::Menu.perform(&:go_to_projects)
            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.go_to_project(name)
            end
          end
        end
      end
    end
  end
end
