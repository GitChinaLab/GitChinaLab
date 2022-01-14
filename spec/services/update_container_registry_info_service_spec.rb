# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateContainerRegistryInfoService do
  let_it_be(:application_settings) { Gitlab::CurrentSettings }
  let_it_be(:api_url) { 'http://registry.gitlab' }

  describe '#execute' do
    before do
      stub_access_token
      stub_container_registry_config(enabled: true, api_url: api_url)
    end

    subject { described_class.new.execute }

    shared_examples 'invalid config' do
      it 'does not update the application settings' do
        expect(application_settings).not_to receive(:update!)

        subject
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when container registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it_behaves_like 'invalid config'
    end

    context 'when container registry api_url is blank' do
      before do
        stub_container_registry_config(api_url: '')
      end

      it_behaves_like 'invalid config'
    end

    context 'when creating a registry client instance' do
      let(:token) { 'foo' }
      let(:client) { ContainerRegistry::Client.new(api_url, token: token) }

      before do
        stub_registry_info({})
      end

      it 'uses a token with no access permissions' do
        expect(Auth::ContainerRegistryAuthenticationService)
          .to receive(:access_token).with([], []).and_return(token)
        expect(ContainerRegistry::Client)
          .to receive(:new).with(api_url, token: token).and_return(client)

        subject
      end
    end

    context 'when unabled to detect the container registry type' do
      it 'sets the application settings to their defaults' do
        stub_registry_info({})

        subject

        application_settings.reload
        expect(application_settings.container_registry_vendor).to be_blank
        expect(application_settings.container_registry_version).to be_blank
        expect(application_settings.container_registry_features).to eq([])
      end
    end

    context 'when able to detect the container registry type' do
      context 'when using the GitLab container registry' do
        it 'updates application settings accordingly' do
          stub_registry_info(vendor: 'gitlab', version: '2.9.1-gitlab', features: %w[a,b,c])

          subject

          application_settings.reload
          expect(application_settings.container_registry_vendor).to eq('gitlab')
          expect(application_settings.container_registry_version).to eq('2.9.1-gitlab')
          expect(application_settings.container_registry_features).to eq(%w[a,b,c])
        end
      end

      context 'when using a third-party container registry' do
        it 'updates application settings accordingly' do
          stub_registry_info(vendor: 'other', version: nil, features: nil)

          subject

          application_settings.reload
          expect(application_settings.container_registry_vendor).to eq('other')
          expect(application_settings.container_registry_version).to be_blank
          expect(application_settings.container_registry_features).to eq([])
        end
      end
    end
  end

  def stub_access_token
    allow(Auth::ContainerRegistryAuthenticationService)
      .to receive(:access_token).with([], []).and_return('foo')
  end

  def stub_registry_info(output)
    allow_next_instance_of(ContainerRegistry::Client) do |client|
      allow(client).to receive(:registry_info).and_return(output)
    end
  end
end
