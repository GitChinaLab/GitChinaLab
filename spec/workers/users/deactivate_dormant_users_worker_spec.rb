# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DeactivateDormantUsersWorker do
  using RSpec::Parameterized::TableSyntax

  describe '#perform' do
    let_it_be(:dormant) { create(:user, last_activity_on: User::MINIMUM_INACTIVE_DAYS.days.ago.to_date) }
    let_it_be(:inactive) { create(:user, last_activity_on: nil) }

    subject(:worker) { described_class.new }

    it 'does not run for GitLab.com' do
      expect(Gitlab).to receive(:com?).and_return(true)
      expect(Gitlab::CurrentSettings).not_to receive(:current_application_settings)

      worker.perform

      expect(User.dormant.count).to eq(1)
      expect(User.with_no_activity.count).to eq(1)
    end

    context 'when automatic deactivation of dormant users is enabled' do
      before do
        stub_application_setting(deactivate_dormant_users: true)
        stub_const("#{described_class.name}::PAUSE_SECONDS", 0)
      end

      it 'deactivates dormant users' do
        freeze_time do
          stub_const("#{described_class.name}::BATCH_SIZE", 1)

          expect(worker).to receive(:sleep).twice

          worker.perform

          expect(User.dormant.count).to eq(0)
          expect(User.with_no_activity.count).to eq(0)
        end
      end

      where(:user_type, :expected_state) do
        :human             | 'deactivated'
        :support_bot       | 'active'
        :alert_bot         | 'active'
        :visual_review_bot | 'active'
        :service_user      | 'deactivated'
        :ghost             | 'active'
        :project_bot       | 'active'
        :migration_bot     | 'active'
        :security_bot      | 'active'
        :automation_bot    | 'active'
      end
      with_them do
        it 'deactivates certain user types' do
          user = create(:user, user_type: user_type, state: :active, last_activity_on: User::MINIMUM_INACTIVE_DAYS.days.ago.to_date)

          worker.perform

          expect(user.reload.state).to eq(expected_state)
        end
      end

      it 'does not deactivate non-active users' do
        human_user = create(:user, user_type: :human, state: :blocked, last_activity_on: User::MINIMUM_INACTIVE_DAYS.days.ago.to_date)
        service_user = create(:user, user_type: :service_user, state: :blocked, last_activity_on: User::MINIMUM_INACTIVE_DAYS.days.ago.to_date)

        worker.perform

        expect(human_user.reload.state).to eq('blocked')
        expect(service_user.reload.state).to eq('blocked')
      end
    end

    context 'when automatic deactivation of dormant users is disabled' do
      before do
        stub_application_setting(deactivate_dormant_users: false)
      end

      it 'does nothing' do
        worker.perform

        expect(User.dormant.count).to eq(1)
        expect(User.with_no_activity.count).to eq(1)
      end
    end
  end
end
