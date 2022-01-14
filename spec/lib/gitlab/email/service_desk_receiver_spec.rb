# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::ServiceDeskReceiver do
  let(:email) { fixture_file('emails/service_desk_custom_address.eml') }
  let(:receiver) { described_class.new(email) }

  context 'when the email contains a valid email address' do
    before do
      stub_service_desk_email_setting(enabled: true, address: 'support+%{key}@example.com')

      handler = double(execute: true, metrics_event: true, metrics_params: true)
      expected_params = [
        an_instance_of(Mail::Message), nil,
        { service_desk_key: 'project_slug-project_key' }
      ]

      expect(Gitlab::Email::Handler::ServiceDeskHandler)
        .to receive(:new).with(*expected_params).and_return(handler)
    end

    context 'when in a To header' do
      it 'finds the service desk key' do
        receiver.execute
      end
    end

    context 'when the email contains a valid email address in a header' do
      context 'when in a Delivered-To header' do
        let(:email) { fixture_file('emails/service_desk_custom_address_reply.eml') }

        it 'finds the service desk key' do
          receiver.execute
        end
      end

      context 'when in a Envelope-To header' do
        let(:email) { fixture_file('emails/service_desk_custom_address_envelope_to.eml') }

        it 'finds the service desk key' do
          receiver.execute
        end
      end

      context 'when in a X-Envelope-To header' do
        let(:email) { fixture_file('emails/service_desk_custom_address_x_envelope_to.eml') }

        it 'finds the service desk key' do
          receiver.execute
        end
      end
    end
  end

  context 'when the email does not contain a valid email address' do
    before do
      stub_service_desk_email_setting(enabled: true, address: 'other_support+%{key}@example.com')
    end

    it 'raises an error' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end
end
