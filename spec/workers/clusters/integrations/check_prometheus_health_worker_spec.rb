# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Integrations::CheckPrometheusHealthWorker, '#perform' do
  subject { described_class.new.perform }

  it 'triggers health service' do
    cluster = create(:cluster)
    allow(Gitlab::Monitor::DemoProjects).to receive(:primary_keys)
    allow(Clusters::Cluster).to receive_message_chain(:with_integration_prometheus, :with_project_http_integrations).and_return([cluster])

    service_instance = instance_double(Clusters::Integrations::PrometheusHealthCheckService)
    expect(Clusters::Integrations::PrometheusHealthCheckService).to receive(:new).with(cluster).and_return(service_instance)
    expect(service_instance).to receive(:execute)

    subject
  end
end
