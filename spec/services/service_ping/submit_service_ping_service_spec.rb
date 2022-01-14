# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::SubmitService do
  include StubRequests
  include UsageDataHelpers

  let(:usage_data_id) { 31643 }
  let(:score_params) do
    {
      score: {
        leader_issues: 10.2,
        instance_issues: 3.2,
        percentage_issues: 31.37,

        leader_notes: 25.3,
        instance_notes: 23.2,

        leader_milestones: 16.2,
        instance_milestones: 5.5,

        leader_boards: 5.2,
        instance_boards: 3.2,

        leader_merge_requests: 5.2,
        instance_merge_requests: 3.2,

        leader_ci_pipelines: 25.1,
        instance_ci_pipelines: 21.3,

        leader_environments: 3.3,
        instance_environments: 2.2,

        leader_deployments: 41.3,
        instance_deployments: 15.2,

        leader_projects_prometheus_active: 0.31,
        instance_projects_prometheus_active: 0.30,

        leader_service_desk_issues: 15.8,
        instance_service_desk_issues: 15.1,

        usage_data_id: usage_data_id,

        non_existing_column: 'value'
      }
    }
  end

  let(:with_dev_ops_score_params) { { dev_ops_score: score_params[:score] } }
  let(:with_conv_index_params) { { conv_index: score_params[:score] } }
  let(:with_usage_data_id_params) { { conv_index: { usage_data_id: usage_data_id } } }

  shared_examples 'does not run' do
    it do
      expect(Gitlab::HTTP).not_to receive(:post)
      expect(Gitlab::UsageData).not_to receive(:data)

      subject.execute
    end
  end

  shared_examples 'does not send a blank usage ping payload' do
    it do
      expect(Gitlab::HTTP).not_to receive(:post)

      expect { subject.execute }.to raise_error(described_class::SubmissionError) do |error|
        expect(error.message).to include('Usage data is blank')
      end
    end
  end

  shared_examples 'saves DevOps report data from the response' do
    it do
      expect { subject.execute }
        .to change { DevOpsReport::Metric.count }
        .by(1)

      expect(DevOpsReport::Metric.last.leader_issues).to eq 10.2
      expect(DevOpsReport::Metric.last.instance_issues).to eq 3.2
      expect(DevOpsReport::Metric.last.percentage_issues).to eq 31.37
    end
  end

  context 'when usage ping is disabled' do
    before do
      stub_application_setting(usage_ping_enabled: false)
    end

    it_behaves_like 'does not run'
  end

  context 'when usage ping is disabled from GitLab config file' do
    before do
      stub_config_setting(usage_ping_enabled: false)
    end

    it_behaves_like 'does not run'
  end

  context 'when product_intelligence_enabled is false' do
    before do
      allow(ServicePing::ServicePingSettings).to receive(:product_intelligence_enabled?).and_return(false)
    end

    it_behaves_like 'does not run'
  end

  context 'when product_intelligence_enabled is true' do
    before do
      stub_usage_data_connections

      allow(ServicePing::ServicePingSettings).to receive(:product_intelligence_enabled?).and_return(true)
    end

    it 'generates service ping' do
      stub_response(body: with_dev_ops_score_params)

      expect(Gitlab::UsageData).to receive(:data).with(force_refresh: true).and_call_original

      subject.execute
    end
  end

  context 'when usage ping is enabled' do
    before do
      stub_usage_data_connections
      stub_application_setting(usage_ping_enabled: true)
    end

    context 'and user requires usage stats consent' do
      before do
        allow(User).to receive(:single_user).and_return(double(:user, requires_usage_stats_consent?: true))
      end

      it_behaves_like 'does not run'
    end

    it 'sends a POST request' do
      response = stub_response(body: with_dev_ops_score_params)

      subject.execute

      expect(response).to have_been_requested
    end

    it 'forces a refresh of usage data statistics before submitting' do
      stub_response(body: with_dev_ops_score_params)

      expect(Gitlab::UsageData).to receive(:data).with(force_refresh: true).and_call_original

      subject.execute
    end

    context 'when conv_index data is passed' do
      before do
        stub_response(body: with_conv_index_params)
      end

      it_behaves_like 'saves DevOps report data from the response'

      it 'saves usage_data_id to version_usage_data_id_value' do
        recorded_at = Time.current
        usage_data = { uuid: 'uuid', recorded_at: recorded_at }

        expect(Gitlab::UsageData).to receive(:data).with(force_refresh: true).and_return(usage_data)

        subject.execute

        raw_usage_data = RawUsageData.find_by(recorded_at: recorded_at)

        expect(raw_usage_data.version_usage_data_id_value).to eq(31643)
      end
    end

    context 'when only usage_data_id is passed in response' do
      before do
        stub_response(body: with_usage_data_id_params)
      end

      it 'does not save DevOps report data' do
        expect { subject.execute }.not_to change { DevOpsReport::Metric.count }
      end

      it 'saves usage_data_id to version_usage_data_id_value' do
        recorded_at = Time.current
        usage_data = { uuid: 'uuid', recorded_at: recorded_at }

        expect(Gitlab::UsageData).to receive(:data).with(force_refresh: true).and_return(usage_data)

        subject.execute

        raw_usage_data = RawUsageData.find_by(recorded_at: recorded_at)

        expect(raw_usage_data.version_usage_data_id_value).to eq(31643)
      end
    end

    context 'when version app usage_data_id is invalid' do
      let(:usage_data_id) { -1000 }

      before do
        stub_response(body: with_conv_index_params)
      end

      it 'raises an exception' do
        expect { subject.execute }.to raise_error(described_class::SubmissionError) do |error|
          expect(error.message).to include('Invalid usage_data_id in response: -1000')
        end
      end
    end

    context 'when DevOps report data is passed' do
      before do
        stub_response(body: with_dev_ops_score_params)
      end

      it_behaves_like 'saves DevOps report data from the response'
    end

    context 'with saving raw_usage_data' do
      before do
        stub_response(body: with_dev_ops_score_params)
      end

      it 'creates a raw_usage_data record' do
        expect { subject.execute }.to change(RawUsageData, :count).by(1)
      end

      it 'saves the correct payload' do
        recorded_at = Time.current
        usage_data = { uuid: 'uuid', recorded_at: recorded_at }

        expect(Gitlab::UsageData).to receive(:data).with(force_refresh: true).and_return(usage_data)

        subject.execute

        raw_usage_data = RawUsageData.find_by(recorded_at: recorded_at)

        expect(raw_usage_data.recorded_at).to be_like_time(recorded_at)
        expect(raw_usage_data.payload.to_json).to eq(usage_data.to_json)
      end
    end

    context 'and usage ping response has unsuccessful status' do
      before do
        stub_response(body: nil, status: 504)
      end

      it 'raises an exception' do
        expect { subject.execute }.to raise_error(described_class::SubmissionError) do |error|
          expect(error.message).to include('Unsuccessful response code: 504')
        end
      end
    end

    context 'and usage data is empty string' do
      before do
        allow(Gitlab::UsageData).to receive(:data).and_return({})
      end

      it_behaves_like 'does not send a blank usage ping payload'
    end

    context 'and usage data is nil' do
      before do
        allow(ServicePing::BuildPayloadService).to receive(:execute).and_return(nil)
        allow(Gitlab::UsageData).to receive(:data).and_return(nil)
      end

      it_behaves_like 'does not send a blank usage ping payload'
    end

    context 'if payload service fails' do
      before do
        stub_response(body: with_dev_ops_score_params)
        allow(ServicePing::BuildPayloadService).to receive(:execute).and_raise(described_class::SubmissionError, 'SubmissionError')
      end

      it 'calls UsageData .data method' do
        usage_data = build_usage_data

        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)

        subject.execute
      end
    end

    context 'calls BuildPayloadService first' do
      before do
        stub_response(body: with_dev_ops_score_params)
      end

      it 'returns usage data' do
        usage_data = build_usage_data

        expect_next_instance_of(ServicePing::BuildPayloadService) do |service|
          expect(service).to receive(:execute).and_return(usage_data)
        end

        subject.execute
      end
    end

    context 'if version app response fails' do
      before do
        stub_response(body: with_dev_ops_score_params, status: 404)

        usage_data = build_usage_data
        allow_next_instance_of(ServicePing::BuildPayloadService) do |service|
          allow(service).to receive(:execute).and_return(usage_data)
        end
      end

      it 'calls UsageData .data method' do
        usage_data = build_usage_data

        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)

        # SubmissionError is raised as a result of 404 in response from HTTP Request
        expect { subject.execute }.to raise_error(described_class::SubmissionError)
      end
    end

    context 'when skip_db_write passed to service' do
      let(:subject) { ServicePing::SubmitService.new(skip_db_write: true) }

      before do
        stub_response(body: with_dev_ops_score_params)
      end

      it 'does not save RawUsageData' do
        expect { subject.execute }
          .not_to change { RawUsageData.count }
      end

      it 'does not call DevOpsReport service' do
        expect(ServicePing::DevopsReportService).not_to receive(:new)

        subject.execute
      end
    end
  end

  describe '#url' do
    let(:url) { subject.url.to_s }

    context 'when Rails.env is production' do
      before do
        stub_rails_env('production')
      end

      it 'points to the production Version app' do
        expect(url).to eq("#{described_class::PRODUCTION_BASE_URL}/#{described_class::USAGE_DATA_PATH}")
      end
    end

    context 'when Rails.env is not production' do
      before do
        stub_rails_env('development')
      end

      it 'points to the staging Version app' do
        expect(url).to eq("#{described_class::STAGING_BASE_URL}/#{described_class::USAGE_DATA_PATH}")
      end
    end
  end

  def stub_response(url: subject.url, body:, status: 201)
    stub_full_request(url, method: :post)
      .to_return(
        headers: { 'Content-Type' => 'application/json' },
        body: body.to_json,
        status: status
      )
  end

  def build_usage_data
    { uuid: 'uuid', recorded_at: Time.current }
  end
end
