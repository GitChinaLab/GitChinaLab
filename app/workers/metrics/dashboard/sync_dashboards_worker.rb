# frozen_string_literal: true

module Metrics
  module Dashboard
    class SyncDashboardsWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      feature_category :metrics

      idempotent!

      def perform(project_id)
        project = Project.find(project_id)
        dashboard_paths = ::Gitlab::Metrics::Dashboard::RepoDashboardFinder.list_dashboards(project)

        dashboard_paths.each do |dashboard_path|
          ::Gitlab::Metrics::Dashboard::Importer.new(dashboard_path, project).execute!
        end
      end
    end
  end
end
