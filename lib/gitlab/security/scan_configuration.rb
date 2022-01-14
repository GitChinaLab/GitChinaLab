# frozen_string_literal: true

module Gitlab
  module Security
    class ScanConfiguration
      include ::Gitlab::Utils::StrongMemoize
      include Gitlab::Routing.url_helpers

      attr_reader :type

      def initialize(project:, type:, configured: false)
        @project = project
        @type = type
        @configured = configured
      end

      def available?
        # SAST and Secret Detection are always available, but this isn't
        # reflected by our license model yet.
        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/333113
        %i[sast secret_detection].include?(type)
      end

      def configured?
        configured
      end

      def configuration_path
        configurable_scans[type]
      end

      private

      attr_reader :project, :configured

      def configurable_scans
        strong_memoize(:configurable_scans) do
          {
            sast: project_security_configuration_sast_path(project)
          }
        end
      end
    end
  end
end

Gitlab::Security::ScanConfiguration.prepend_mod_with('Gitlab::Security::ScanConfiguration')
