# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::FindCachedManifestService do
  include DependencyProxyHelpers

  let_it_be(:image) { 'alpine' }
  let_it_be(:tag) { 'latest' }
  let_it_be(:dependency_proxy_manifest) { create(:dependency_proxy_manifest, file_name: "#{image}:#{tag}.json") }

  let(:manifest) { dependency_proxy_manifest.file.read }
  let(:group) { dependency_proxy_manifest.group }
  let(:token) { Digest::SHA256.hexdigest('123') }
  let(:headers) do
    {
      DependencyProxy::Manifest::DIGEST_HEADER => dependency_proxy_manifest.digest,
      'content-type' => dependency_proxy_manifest.content_type
    }
  end

  describe '#execute' do
    subject { described_class.new(group, image, tag, token).execute }

    shared_examples 'downloading the manifest' do
      it 'downloads manifest from remote registry if there is no cached one', :aggregate_failures do
        expect { subject }.to change { group.dependency_proxy_manifests.count }.by(1)
        expect(subject[:status]).to eq(:success)
        expect(subject[:manifest]).to be_a(DependencyProxy::Manifest)
        expect(subject[:manifest]).to be_persisted
        expect(subject[:from_cache]).to eq false
      end
    end

    shared_examples 'returning no manifest' do
      it 'returns a nil manifest' do
        expect(subject[:status]).to eq(:success)
        expect(subject[:from_cache]).to eq false
        expect(subject[:manifest]).to be_nil
      end
    end

    context 'when no manifest exists' do
      let_it_be(:image) { 'new-image' }

      context 'successful head request' do
        before do
          stub_manifest_head(image, tag, headers: headers)
          stub_manifest_download(image, tag, headers: headers)
        end

        it_behaves_like 'returning no manifest'
      end

      context 'failed head request' do
        before do
          stub_manifest_head(image, tag, status: :error)
          stub_manifest_download(image, tag, headers: headers)
        end

        it_behaves_like 'returning no manifest'
      end
    end

    context 'when manifest exists' do
      before do
        stub_manifest_head(image, tag, headers: headers)
      end

      shared_examples 'using the cached manifest' do
        it 'uses cached manifest instead of downloading one', :aggregate_failures do
          expect { subject }.to change { dependency_proxy_manifest.reload.read_at }

          expect(subject[:status]).to eq(:success)
          expect(subject[:manifest]).to be_a(DependencyProxy::Manifest)
          expect(subject[:manifest]).to eq(dependency_proxy_manifest)
          expect(subject[:from_cache]).to eq true
        end
      end

      it_behaves_like 'using the cached manifest'

      context 'when digest is stale' do
        let(:digest) { 'new-digest' }
        let(:content_type) { 'new-content-type' }

        before do
          stub_manifest_head(image, tag, headers: { DependencyProxy::Manifest::DIGEST_HEADER => digest, 'content-type' => content_type })
          stub_manifest_download(image, tag, headers: { DependencyProxy::Manifest::DIGEST_HEADER => digest, 'content-type' => content_type })
        end

        it_behaves_like 'returning no manifest'
      end

      context 'when the cached manifest is expired' do
        before do
          dependency_proxy_manifest.update_column(:status, DependencyProxy::Manifest.statuses[:expired])
          stub_manifest_head(image, tag, headers: headers)
          stub_manifest_download(image, tag, headers: headers)
        end

        it_behaves_like 'returning no manifest'
      end

      context 'failed connection' do
        before do
          expect(DependencyProxy::HeadManifestService).to receive(:new).and_raise(Net::OpenTimeout)
        end

        it_behaves_like 'using the cached manifest'

        context 'and no manifest is cached' do
          let_it_be(:image) { 'new-image' }

          it 'returns an error', :aggregate_failures do
            expect(subject[:status]).to eq(:error)
            expect(subject[:http_status]).to eq(503)
            expect(subject[:message]).to eq('Failed to download the manifest from the external registry')
          end
        end
      end
    end
  end
end
