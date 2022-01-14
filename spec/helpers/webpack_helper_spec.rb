# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebpackHelper do
  let(:source) { 'foo.js' }
  let(:asset_path) { "/assets/webpack/#{source}" }

  describe '#prefetch_link_tag' do
    it 'returns prefetch link tag' do
      expect(helper.prefetch_link_tag(source)).to eq("<link rel=\"prefetch\" href=\"/#{source}\">")
    end
  end

  describe '#webpack_preload_asset_tag' do
    before do
      allow(Gitlab::Webpack::Manifest).to receive(:asset_paths).and_return([asset_path])
      allow(helper).to receive(:content_security_policy_nonce).and_return('noncevalue')
    end

    it 'preloads the resource by default' do
      expect(helper).to receive(:preload_link_tag).with(asset_path, {}).and_call_original

      output = helper.webpack_preload_asset_tag(source)

      expect(output).to eq("<link rel=\"preload\" href=\"#{asset_path}\" as=\"script\" type=\"text/javascript\" nonce=\"noncevalue\">")
    end

    it 'prefetches the resource if explicitly asked' do
      expect(helper).to receive(:prefetch_link_tag).with(asset_path).and_call_original

      output = helper.webpack_preload_asset_tag(source, prefetch: true)

      expect(output).to eq("<link rel=\"prefetch\" href=\"#{asset_path}\">")
    end
  end
end
