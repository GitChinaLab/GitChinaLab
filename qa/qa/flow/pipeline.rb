# frozen_string_literal: true

module QA
  module Flow
    module Pipeline
      module_function

      # In some cases we don't need to wait for anything, blocked, running or pending is acceptable
      # Some cases only we do need pipeline to finish with expected condition (completed, succeeded or replicated)
      def visit_latest_pipeline(pipeline_condition: nil)
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:"wait_for_latest_pipeline_#{pipeline_condition}") if pipeline_condition
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)
      end

      def wait_for_latest_pipeline(pipeline_condition:)
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:"wait_for_latest_pipeline_#{pipeline_condition}")
      end
    end
  end
end
