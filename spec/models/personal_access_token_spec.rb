# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessToken do
  subject { described_class }

  describe '.build' do
    let(:personal_access_token) { build(:personal_access_token) }
    let(:invalid_personal_access_token) { build(:personal_access_token, :invalid) }

    it 'is a valid personal access token' do
      expect(personal_access_token).to be_valid
    end

    it 'ensures that the token is generated' do
      invalid_personal_access_token.save!

      expect(invalid_personal_access_token).to be_valid
      expect(invalid_personal_access_token.token).not_to be_nil
    end
  end

  describe 'scopes' do
    describe '.for_user' do
      it 'returns personal access tokens of specified user only' do
        user_1 = create(:user)
        token_of_user_1 = create(:personal_access_token, user: user_1)
        create_list(:personal_access_token, 2)

        expect(described_class.for_user(user_1)).to contain_exactly(token_of_user_1)
      end
    end

    describe '.for_users' do
      it 'returns personal access tokens for the specified users only' do
        user_1 = create(:user)
        user_2 = create(:user)
        token_of_user_1 = create(:personal_access_token, user: user_1)
        token_of_user_2 = create(:personal_access_token, user: user_2)
        create_list(:personal_access_token, 3)

        expect(described_class.for_users([user_1, user_2])).to contain_exactly(token_of_user_1, token_of_user_2)
      end
    end
  end

  describe ".active?" do
    let(:active_personal_access_token) { build(:personal_access_token) }
    let(:revoked_personal_access_token) { build(:personal_access_token, :revoked) }
    let(:expired_personal_access_token) { build(:personal_access_token, :expired) }

    it "returns false if the personal_access_token is revoked" do
      expect(revoked_personal_access_token).not_to be_active
    end

    it "returns false if the personal_access_token is expired" do
      expect(expired_personal_access_token).not_to be_active
    end

    it "returns true if the personal_access_token is not revoked and not expired" do
      expect(active_personal_access_token).to be_active
    end
  end

  describe 'revoke!' do
    let(:active_personal_access_token) { create(:personal_access_token) }

    it 'revokes the token' do
      active_personal_access_token.revoke!

      expect(active_personal_access_token).to be_revoked
    end
  end

  describe '#expired_but_not_enforced?' do
    let(:token) { build(:personal_access_token) }

    it 'returns false', :aggregate_failures do
      expect(token).not_to be_expired_but_not_enforced
    end
  end

  describe 'Redis storage' do
    let(:user_id) { 123 }
    let(:token) { 'KS3wegQYXBLYhQsciwsj' }

    context 'reading encrypted data' do
      before do
        subject.redis_store!(user_id, token)
      end

      it 'returns stored data' do
        expect(subject.redis_getdel(user_id)).to eq(token)
      end
    end

    context 'reading unencrypted data' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(described_class.redis_shared_state_key(user_id),
                    token,
                    ex: PersonalAccessToken::REDIS_EXPIRY_TIME)
        end
      end

      it 'returns stored data unmodified' do
        expect(subject.redis_getdel(user_id)).to eq(token)
      end
    end

    context 'after deletion' do
      before do
        subject.redis_store!(user_id, token)

        expect(subject.redis_getdel(user_id)).to eq(token)
      end

      it 'token is removed' do
        expect(subject.redis_getdel(user_id)).to be_nil
      end
    end
  end

  context "validations" do
    let(:personal_access_token) { build(:personal_access_token) }

    it "requires at least one scope" do
      personal_access_token.scopes = []

      expect(personal_access_token).not_to be_valid
      expect(personal_access_token.errors[:scopes].first).to eq "can't be blank"
    end

    it "allows creating a token with API scopes" do
      personal_access_token.scopes = [:api, :read_user]

      expect(personal_access_token).to be_valid
    end

    context 'when registry is disabled' do
      before do
        stub_container_registry_config(enabled: false)
      end

      it "rejects creating a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
      end

      it "allows revoking a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        personal_access_token.revoke!

        expect(personal_access_token).to be_revoked
      end
    end

    context 'when registry is enabled' do
      before do
        stub_container_registry_config(enabled: true)
      end

      it "allows creating a token with read_registry scope" do
        personal_access_token.scopes = [:read_registry]

        expect(personal_access_token).to be_valid
      end
    end

    it "rejects creating a token with unavailable scopes" do
      personal_access_token.scopes = [:openid, :api]

      expect(personal_access_token).not_to be_valid
      expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
    end
  end

  describe 'scopes' do
    describe '.expiring_and_not_notified' do
      let_it_be(:expired_token) { create(:personal_access_token, expires_at: 2.days.ago) }
      let_it_be(:revoked_token) { create(:personal_access_token, revoked: true) }
      let_it_be(:valid_token_and_notified) { create(:personal_access_token, expires_at: 2.days.from_now, expire_notification_delivered: true) }
      let_it_be(:valid_token) { create(:personal_access_token, expires_at: 2.days.from_now) }
      let_it_be(:long_expiry_token) { create(:personal_access_token, expires_at: '999999-12-31'.to_date) }

      context 'in one day' do
        it "doesn't have any tokens" do
          expect(described_class.expiring_and_not_notified(1.day.from_now)).to be_empty
        end
      end

      context 'in three days' do
        it 'only includes a valid token' do
          expect(described_class.expiring_and_not_notified(3.days.from_now)).to contain_exactly(valid_token)
        end
      end
    end

    describe '.expired_today_and_not_notified' do
      let_it_be(:active) { create(:personal_access_token) }
      let_it_be(:expired_yesterday) { create(:personal_access_token, expires_at: Date.yesterday) }
      let_it_be(:revoked_token) { create(:personal_access_token, expires_at: Date.current, revoked: true) }
      let_it_be(:expired_today) { create(:personal_access_token, expires_at: Date.current) }
      let_it_be(:expired_today_and_notified) { create(:personal_access_token, expires_at: Date.current, after_expiry_notification_delivered: true) }

      it 'returns tokens that have expired today' do
        expect(described_class.expired_today_and_not_notified).to contain_exactly(expired_today)
      end
    end

    describe '.without_impersonation' do
      let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation) }
      let_it_be(:personal_access_token) { create(:personal_access_token) }

      it 'returns only non-impersonation tokens' do
        expect(described_class.without_impersonation).to contain_exactly(personal_access_token)
      end
    end

    describe 'revoke scopes' do
      let_it_be(:revoked_token) { create(:personal_access_token, :revoked) }
      let_it_be(:non_revoked_token) { create(:personal_access_token, revoked: false) }
      let_it_be(:non_revoked_token2) { create(:personal_access_token, revoked: nil) }

      describe '.revoked' do
        it { expect(described_class.revoked).to contain_exactly(revoked_token) }
      end

      describe '.not_revoked' do
        it { expect(described_class.not_revoked).to contain_exactly(non_revoked_token, non_revoked_token2) }
      end
    end
  end

  describe '.simple_sorts' do
    it 'includes overridden keys' do
      expect(described_class.simple_sorts.keys).to include(*%w(expires_at_asc expires_at_desc))
    end
  end

  describe 'ordering by expires_at' do
    let_it_be(:earlier_token) { create(:personal_access_token, expires_at: 2.days.ago) }
    let_it_be(:later_token) { create(:personal_access_token, expires_at: 1.day.ago) }

    describe '.order_expires_at_asc' do
      it 'returns ordered list in asc order of expiry date' do
        expect(described_class.order_expires_at_asc).to match [earlier_token, later_token]
      end
    end

    describe '.order_expires_at_desc' do
      it 'returns ordered list in desc order of expiry date' do
        expect(described_class.order_expires_at_desc).to match [later_token, earlier_token]
      end
    end
  end
end
