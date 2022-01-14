# frozen_string_literal: true

require 'active_support/core_ext/enumerable'

module QA
  module Runtime
    class AllureReport
      extend QA::Support::API

      class << self
        # Configure allure reports
        #
        # @return [void]
        def configure!
          return unless Env.generate_allure_report?

          configure_allure
          configure_attachments
          configure_rspec
        end

        private

        # Configure allure reporter
        #
        # @return [void]
        def configure_allure
          # Match job names like ee:relative, ce:update etc. and set as execution environment
          env_matcher = /^(?<env>\w{2}:\S+)/

          AllureRspec.configure do |config|
            config.results_directory = 'tmp/allure-results'
            config.clean_results_directory = true

            # automatically attach links to testcases and issues
            config.tms_tag = :testcase
            config.link_tms_pattern = '{}'
            config.issue_tag = :issue
            config.link_issue_pattern = '{}'

            config.environment_properties = environment_info if Env.running_in_ci?

            # Set custom environment name to separate same specs executed on different environments
            if Env.running_in_ci? && Env.ci_job_name.match?(env_matcher)
              config.environment = Env.ci_job_name.match(env_matcher).named_captures['env']
            end
          end
        end

        # Set up failure screenshot attachments
        #
        # @return [void]
        def configure_attachments
          Capybara::Screenshot.after_save_screenshot do |path|
            Allure.add_attachment(
              name: 'screenshot',
              source: File.open(path),
              type: Allure::ContentType::PNG,
              test_case: true
            )
          end
          Capybara::Screenshot.after_save_html do |path|
            Allure.add_attachment(
              name: 'html',
              source: File.open(path),
              type: 'text/html',
              test_case: true
            )
          end
        end

        # Configure rspec
        #
        # @return [void]
        def configure_rspec
          RSpec.configure do |config|
            config.add_formatter(AllureRspecFormatter)
            config.add_formatter(QA::Support::Formatters::AllureMetadataFormatter)

            config.append_after do |example|
              Allure.add_attachment(
                name: 'browser.log',
                source: Capybara.current_session.driver.browser.logs.get(:browser).map(&:to_s).join("\n\n"),
                type: Allure::ContentType::TXT,
                test_case: true
              )
            end
          end
        end

        # Gitlab version and revision information
        #
        # @return [Hash]
        def environment_info
          lambda do
            return {} unless Env.admin_personal_access_token || Env.personal_access_token

            client = Env.admin_personal_access_token ? API::Client.as_admin : API::Client.new
            response = get(API::Request.new(client, '/version').url)

            JSON.parse(response.body, symbolize_names: true)
          rescue StandardError, ArgumentError => e
            Logger.error("Failed to attach version info to allure report: #{e}")
            {}
          end
        end
      end
    end
  end
end
