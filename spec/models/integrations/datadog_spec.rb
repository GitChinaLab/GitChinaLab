# frozen_string_literal: true
require 'securerandom'

require 'spec_helper'

RSpec.describe Integrations::Datadog do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
  let_it_be(:retried_build) { create(:ci_build, :retried, pipeline: pipeline) }

  let(:active) { true }
  let(:dd_site) { 'datadoghq.com' }
  let(:default_url) { 'https://webhook-intake.datadoghq.com/api/v2/webhook' }
  let(:api_url) { '' }
  let(:api_key) { SecureRandom.hex(32) }
  let(:dd_env) { 'ci' }
  let(:dd_service) { 'awesome-gitlab' }

  let(:expected_hook_url) { default_url + "?dd-api-key=#{api_key}&env=#{dd_env}&service=#{dd_service}" }

  let(:instance) do
    described_class.new(
      active: active,
      project: project,
      datadog_site: dd_site,
      api_url: api_url,
      api_key: api_key,
      datadog_env: dd_env,
      datadog_service: dd_service
    )
  end

  let(:saved_instance) do
    instance.save!
    instance
  end

  let(:pipeline_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }
  let(:build_data) { Gitlab::DataBuilder::Build.build(build) }

  it_behaves_like Integrations::HasWebHook do
    let(:integration) { instance }
    let(:hook_url) { "#{described_class::URL_TEMPLATE % { datadog_domain: dd_site }}?dd-api-key=#{api_key}&env=#{dd_env}&service=#{dd_service}" }
  end

  describe 'validations' do
    subject { instance }

    context 'when service is active' do
      let(:active) { true }

      it { is_expected.to validate_presence_of(:api_key) }
      it { is_expected.to allow_value(api_key).for(:api_key) }
      it { is_expected.not_to allow_value('87dab2403c9d462 87aec4d9214edb1e').for(:api_key) }
      it { is_expected.not_to allow_value('................................').for(:api_key) }

      context 'when selecting site' do
        let(:dd_site) { 'datadoghq.com' }
        let(:api_url) { '' }

        it { is_expected.to validate_presence_of(:datadog_site) }
        it { is_expected.not_to validate_presence_of(:api_url) }
        it { is_expected.not_to allow_value('datadog hq.com').for(:datadog_site) }
      end

      context 'with custom api_url' do
        let(:dd_site) { '' }
        let(:api_url) { 'https://webhook-intake.datad0g.com/api/v2/webhook' }

        it { is_expected.not_to validate_presence_of(:datadog_site) }
        it { is_expected.to validate_presence_of(:api_url) }
        it { is_expected.to allow_value(api_url).for(:api_url) }
        it { is_expected.not_to allow_value('example.com').for(:api_url) }
      end

      context 'when missing site and api_url' do
        let(:dd_site) { '' }
        let(:api_url) { '' }

        it { is_expected.not_to be_valid }
        it { is_expected.to validate_presence_of(:datadog_site) }
        it { is_expected.to validate_presence_of(:api_url) }
      end

      context 'when providing both site and api_url' do
        let(:dd_site) { 'datadoghq.com' }
        let(:api_url) { default_url }

        it { is_expected.not_to allow_value('datadog hq.com').for(:datadog_site) }
        it { is_expected.not_to allow_value('example.com').for(:api_url) }
      end
    end

    context 'when integration is not active' do
      let(:active) { false }

      it { is_expected.to be_valid }
      it { is_expected.not_to validate_presence_of(:api_key) }
    end
  end

  describe '#hook_url' do
    subject { instance.hook_url }

    context 'with standard site URL' do
      it { is_expected.to eq(expected_hook_url) }
    end

    context 'with custom URL' do
      let(:api_url) { 'https://webhook-intake.datad0g.com/api/v2/webhook' }

      it { is_expected.to eq(api_url + "?dd-api-key=#{api_key}&env=#{dd_env}&service=#{dd_service}") }

      context 'blank' do
        let(:api_url) { '' }

        it { is_expected.to eq(expected_hook_url) }
      end
    end

    context 'without optional params' do
      let(:dd_service) { '' }
      let(:dd_env) { '' }

      it { is_expected.to eq(default_url + "?dd-api-key=#{api_key}") }
    end
  end

  describe '#test' do
    subject(:result) { saved_instance.test(pipeline_data) }

    let(:body) { 'OK' }
    let(:status) { 200 }

    before do
      stub_request(:post, expected_hook_url).to_return(body: body, status: status)
    end

    context 'when request is successful with a HTTP 200 status' do
      it { is_expected.to eq({ success: true, result: 'OK' }) }
    end

    context 'when request is successful with a HTTP 202 status' do
      let(:status) { 202 }

      it { is_expected.to eq({ success: true, result: 'OK' }) }
    end

    context 'when request fails with a HTTP 500 status' do
      let(:status) { 500 }
      let(:body) { 'CRASH!!!' }

      it { is_expected.to eq({ success: false, result: 'CRASH!!!' }) }
    end
  end

  describe '#execute' do
    around do |example|
      freeze_time { example.run }
    end

    before do
      stub_request(:post, expected_hook_url)
      saved_instance.execute(data)
    end

    context 'with pipeline data' do
      let(:data) { pipeline_data }
      let(:expected_headers) { { WebHookService::GITLAB_EVENT_HEADER => 'Pipeline Hook' } }
      let(:expected_body) { data.with_retried_builds.to_json }

      it { expect(a_request(:post, expected_hook_url).with(headers: expected_headers, body: expected_body)).to have_been_made }
    end

    context 'with job data' do
      let(:data) { build_data }
      let(:expected_headers) { { WebHookService::GITLAB_EVENT_HEADER => 'Job Hook' } }
      let(:expected_body) { data.to_json }

      it { expect(a_request(:post, expected_hook_url).with(headers: expected_headers, body: expected_body)).to have_been_made }
    end
  end
end
