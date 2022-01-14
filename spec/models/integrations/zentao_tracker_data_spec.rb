# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ZentaoTrackerData do
  describe 'factory available' do
    let(:zentao_tracker_data) { create(:zentao_tracker_data) }

    it { expect(zentao_tracker_data.valid?).to eq true }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:integration) }
  end

  describe 'encrypted attributes' do
    subject { described_class.encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:url, :api_url, :zentao_product_xid, :api_token) }
  end
end
