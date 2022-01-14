# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group callouts' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'POST /-/users/group_callouts' do
    let(:params) { { feature_name: feature_name, group_id: group.id } }

    subject { post group_callouts_path, params: params, headers: { 'ACCEPT' => 'application/json' } }

    context 'with valid feature name and group' do
      let(:feature_name) { Users::GroupCallout.feature_names.each_key.first }

      context 'when callout entry does not exist' do
        it 'creates a callout entry with dismissed state' do
          expect { subject }.to change { Users::GroupCallout.count }.by(1)
        end

        it 'returns success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when callout entry already exists' do
        let!(:callout) do
          create(:group_callout,
                 feature_name: Users::GroupCallout.feature_names.each_key.first,
                 user: user,
                 group: group)
        end

        it 'returns success', :aggregate_failures do
          expect { subject }.not_to change { Users::GroupCallout.count }
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with invalid feature name' do
      let(:feature_name) { 'bogus_feature_name' }

      it 'returns bad request' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
