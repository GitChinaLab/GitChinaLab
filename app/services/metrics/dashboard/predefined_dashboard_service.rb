# frozen_string_literal: true

module Metrics
  module Dashboard
    class PredefinedDashboardService < ::Metrics::Dashboard::BaseService
      # These constants should be overridden in the inheriting class. For Ex:
      # DASHBOARD_PATH = 'config/prometheus/common_metrics.yml'
      # DASHBOARD_NAME = 'Default'
      DASHBOARD_PATH = nil
      DASHBOARD_NAME = nil

      SEQUENCE = [
        STAGES::MetricEndpointInserter,
        STAGES::VariableEndpointInserter,
        STAGES::PanelIdsInserter
      ].freeze

      class << self
        def valid_params?(params)
          matching_dashboard?(params[:dashboard_path])
        end

        def matching_dashboard?(filepath)
          filepath == self::DASHBOARD_PATH
        end

        def out_of_the_box_dashboard?
          true
        end
      end

      # Returns an un-processed dashboard from the cache.
      def raw_dashboard
        Gitlab::Metrics::Dashboard::Cache.fetch(cache_key) { get_raw_dashboard }
      end

      private

      def dashboard_version
        raise NotImplementedError
      end

      def cache_key
        "metrics_dashboard_#{dashboard_path}_#{dashboard_version}"
      end

      def dashboard_path
        self.class::DASHBOARD_PATH
      end

      # Returns the base metrics shipped with every GitLab service.
      def get_raw_dashboard
        yml = File.read(Rails.root.join(dashboard_path))

        load_yaml(yml)
      end

      def sequence
        self.class::SEQUENCE
      end
    end
  end
end
