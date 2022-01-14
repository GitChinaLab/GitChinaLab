# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserPreferences::UpdateService do
  let(:user) { create(:user) }
  let(:params) { { view_diffs_file_by_file: false } }

  describe '#execute' do
    subject(:service) { described_class.new(user, params) }

    context 'successfully updating the record' do
      it 'updates the preference and returns a success' do
        result = service.execute

        expect(result.status).to eq(:success)
        expect(result.payload[:preferences].view_diffs_file_by_file).to eq(params[:view_diffs_file_by_file])
      end
    end

    context 'unsuccessfully updating the record' do
      before do
        allow(user.user_preference).to receive(:update).and_return(false)
      end

      it 'returns an error' do
        result = service.execute

        expect(result.status).to eq(:error)
      end
    end
  end
end
