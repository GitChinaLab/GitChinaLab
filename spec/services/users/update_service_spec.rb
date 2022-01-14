# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateService do
  let(:password) { 'longsecret987!' }
  let(:user) { create(:user, password: password, password_confirmation: password) }

  describe '#execute' do
    it 'updates time preferences' do
      result = update_user(user, timezone: 'Europe/Warsaw', time_display_relative: true, time_format_in_24h: false)

      expect(result).to eq(status: :success)
      expect(user.reload.timezone).to eq('Europe/Warsaw')
      expect(user.time_display_relative).to eq(true)
      expect(user.time_format_in_24h).to eq(false)
    end

    it 'returns an error result when record cannot be updated' do
      result = {}
      expect do
        result = update_user(user, { email: 'invalid', validation_password: password })
      end.not_to change { user.reload.email }
      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Email is invalid')
    end

    it 'includes namespace error messages' do
      create(:group, path: 'taken')
      result = {}
      expect do
        result = update_user(user, { username: 'taken' })
      end.not_to change { user.reload.username }
      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('A user, alias, or group already exists with that username.')
    end

    it 'updates the status if status params were given' do
      update_user(user, status: { message: "On a call" })

      expect(user.status.message).to eq("On a call")
    end

    it 'does not delete the status if no status param was passed' do
      create(:user_status, user: user, message: 'Busy!')

      update_user(user, name: 'New name')

      expect(user.status.message).to eq('Busy!')
    end

    it 'includes status error messages' do
      result = update_user(user, status: { emoji: "Moo!" })

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq("Emoji is not a valid emoji name")
    end

    it 'updates user detail with provided attributes' do
      result = update_user(user, job_title: 'Backend Engineer')

      expect(result).to eq(status: :success)
      expect(user.job_title).to eq('Backend Engineer')
    end

    context 'updating canonical email' do
      context 'if email was changed' do
        subject do
          update_user(user, email: 'user+extrastuff@example.com', validation_password: password)
        end

        it 'calls canonicalize_email' do
          expect_next_instance_of(Users::UpdateCanonicalEmailService) do |service|
            expect(service).to receive(:execute)
          end

          subject
        end

        context 'when check_password is true' do
          def update_user(user, opts)
            described_class.new(user, opts.merge(user: user)).execute(check_password: true)
          end

          it 'returns error if no password confirmation was passed', :aggregate_failures do
            result = {}

            expect do
              result = update_user(user, { email: 'example@example.com' })
            end.not_to change { user.reload.unconfirmed_email }
            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq('Invalid password')
          end

          it 'returns error if wrong password confirmation was passed', :aggregate_failures do
            result = {}

            expect do
              result = update_user(user, { email: 'example@example.com', validation_password: 'wrongpassword' })
            end.not_to change { user.reload.unconfirmed_email }
            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq('Invalid password')
          end

          it 'does not require password if it was automatically set', :aggregate_failures do
            user.update!(password_automatically_set: true)
            result = {}

            expect do
              result = update_user(user, { email: 'example@example.com' })
            end.to change { user.reload.unconfirmed_email }
            expect(result[:status]).to eq(:success)
          end

          it 'does not require a password if the attribute changed does not require it' do
            result = {}

            expect do
              result = update_user(user, { job_title: 'supreme leader of the universe' })
            end.to change { user.reload.job_title }
            expect(result[:status]).to eq(:success)
          end
        end
      end

      context 'when check_password is left to false' do
        it 'does not require a password check', :aggregate_failures do
          result = {}
          expect do
            result = update_user(user, { email: 'example@example.com' })
          end.to change { user.reload.unconfirmed_email }
          expect(result[:status]).to eq(:success)
        end
      end

      context 'if email was NOT changed' do
        it 'skips update canonicalize email service call' do
          expect do
            update_user(user, job_title: 'supreme leader of the universe')
          end.not_to change { user.user_canonical_email }
        end
      end
    end

    def update_user(user, opts)
      described_class.new(user, opts.merge(user: user)).execute
    end
  end

  describe '#execute!' do
    it 'updates the name' do
      service = described_class.new(user, user: user, name: 'New Name')
      expect(service).not_to receive(:notify_new_user)

      result = service.execute!

      expect(result).to be true
      expect(user.name).to eq('New Name')
    end

    it 'raises an error when record cannot be updated' do
      expect do
        update_user(user, email: 'invalid', validation_password: password)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fires system hooks when a new user is saved' do
      system_hook_service = spy(:system_hook_service)
      user = build(:user)
      service = described_class.new(user, user: user, name: 'John Doe')
      expect(service).to receive(:notify_new_user).and_call_original
      expect(service).to receive(:system_hook_service).and_return(system_hook_service)

      service.execute

      expect(system_hook_service).to have_received(:execute_hooks_for).with(user, :create)
    end

    def update_user(user, opts)
      described_class.new(user, opts.merge(user: user)).execute!
    end
  end
end
