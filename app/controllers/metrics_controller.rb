# frozen_string_literal: true

class MetricsController < ActionController::Base
  include RequiresWhitelistedMonitoringClient

  protect_from_forgery with: :exception, prepend: true

  def index
    response = if Gitlab::Metrics.prometheus_metrics_enabled?
                 Gitlab::Metrics::RailsSlis.initialize_request_slis_if_needed!
                 metrics_service.metrics_text
               else
                 help_page = help_page_url('administration/monitoring/prometheus/gitlab_metrics',
                                           anchor: 'gitlab-prometheus-metrics'
                                          )
                 "# Metrics are disabled, see: #{help_page}\n"
               end

    render plain: response, content_type: 'text/plain; version=0.0.4'
  end

  def system
    render json: system_metrics
  end

  private

  def metrics_service
    @metrics_service ||= MetricsService.new
  end

  def system_metrics
    Gitlab::Metrics::System.summary.merge(
      worker_id: ::Prometheus::PidProvider.worker_id
    )
  end
end
