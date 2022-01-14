# frozen_string_literal: true

module Emails
  module AutoDevops
    def autodevops_disabled_email(pipeline, recipient)
      @pipeline = pipeline
      @project = pipeline.project

      add_project_headers

      mail(to: recipient,
           subject: auto_devops_disabled_subject(@project.name)) do |format|
        format.html { render layout: 'mailer' }
        format.text { render layout: 'mailer' }
      end
    end

    private

    def auto_devops_disabled_subject(project_name)
      subject("Auto DevOps pipeline was disabled for #{project_name}")
    end
  end
end
