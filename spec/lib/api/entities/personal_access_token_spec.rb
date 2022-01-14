# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PersonalAccessToken do
  describe '#as_json' do
    let_it_be(:user) { create(:user) }
    let_it_be(:token) { create(:personal_access_token, user: user, expires_at: nil) }

    let(:entity) { described_class.new(token) }

    it 'returns token data' do
      expect(entity.as_json).to eq({
         id: token.id,
         name: token.name,
         revoked: false,
         created_at: token.created_at,
         scopes: ['api'],
         user_id: user.id,
         last_used_at: nil,
         active: true,
         expires_at: nil
       })
    end
  end
end
