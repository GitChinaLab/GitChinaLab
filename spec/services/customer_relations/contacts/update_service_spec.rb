# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomerRelations::Contacts::UpdateService do
  let_it_be(:user) { create(:user) }

  let(:contact) { create(:contact, first_name: 'Mark', group: group) }

  subject(:update) { described_class.new(group: group, current_user: user, params: params).execute(contact) }

  describe '#execute' do
    context 'when the user has no permission' do
      let_it_be(:group) { create(:group) }

      let(:params) { { first_name: 'Gary' } }

      it 'returns an error' do
        response = update

        expect(response).to be_error
        expect(response.message).to match_array(['You have insufficient permissions to update a contact for this group'])
      end
    end

    context 'when user has permission' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_developer(user)
      end

      context 'when first_name is changed' do
        let(:params) { { first_name: 'Gary' } }

        it 'updates the contact' do
          response = update

          expect(response).to be_success
          expect(response.payload.first_name).to eq('Gary')
        end
      end

      context 'when the contact is invalid' do
        let(:params) { { first_name: nil } }

        it 'returns an error' do
          response = update

          expect(response).to be_error
          expect(response.message).to match_array(["First name can't be blank"])
        end
      end
    end
  end
end
