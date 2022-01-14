# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class JiraImport < Page::Base
          view 'app/assets/javascripts/jira_import/components/jira_import_form.vue' do
            element :jira_project_dropdown
            element :jira_issues_import_button
          end

          def select_jira_project(jira_project)
            select_element(:jira_project_dropdown, jira_project)
          end

          def select_project_and_import(jira_project)
            select_jira_project(jira_project)
            click_element(:jira_issues_import_button)
          end
        end
      end
    end
  end
end
