# frozen_string_literal: true

module Clusters
  module Integrations
    class PrometheusHealthCheckService
      include Gitlab::Utils::StrongMemoize
      include Gitlab::Routing

      def initialize(cluster)
        @cluster = cluster
        @logger = Gitlab::AppJsonLogger.build
      end

      def execute
        raise 'Invalid cluster type. Only project types are allowed.' unless @cluster.project_type?

        return unless prometheus_integration.enabled

        project = @cluster.clusterable

        @logger.info(
          message: 'Prometheus health check',
          cluster_id: @cluster.id,
          newly_unhealthy: became_unhealthy?,
          currently_healthy: currently_healthy?,
          was_healthy: was_healthy?
        )

        send_notification(project) if became_unhealthy?

        prometheus_integration.update_columns(health_status: current_health_status) if health_changed?
      end

      private

      def prometheus_integration
        strong_memoize(:prometheus_integration) do
          @cluster.integration_prometheus
        end
      end

      def current_health_status
        if currently_healthy?
          :healthy
        else
          :unhealthy
        end
      end

      def currently_healthy?
        strong_memoize(:currently_healthy) do
          prometheus_integration.prometheus_client.healthy?
        end
      end

      def became_unhealthy?
        strong_memoize(:became_unhealthy) do
          (was_healthy? || was_unknown?) && !currently_healthy?
        end
      end

      def was_healthy?
        strong_memoize(:was_healthy) do
          prometheus_integration.healthy?
        end
      end

      def was_unknown?
        strong_memoize(:was_unknown) do
          prometheus_integration.unknown?
        end
      end

      def health_changed?
        was_healthy? != currently_healthy?
      end

      def send_notification(project)
        notification_payload = build_notification_payload(project)
        integration = project.alert_management_http_integrations.active.first

        Projects::Alerting::NotifyService.new(project, notification_payload).execute(integration&.token, integration)

        @logger.info(message: 'Successfully notified of Prometheus newly unhealthy', cluster_id: @cluster.id, project_id: project.id)
      end

      def build_notification_payload(project)
        cluster_path = namespace_project_cluster_path(
          project_id: project.path,
          namespace_id: project.namespace.path,
          id: @cluster.id
        )

        {
          title: "Prometheus is Unhealthy. Cluster Name: #{@cluster.name}",
          description: "Prometheus is unhealthy for the cluster: [#{@cluster.name}](#{cluster_path}) attached to project #{project.name}."
        }
      end
    end
  end
end
