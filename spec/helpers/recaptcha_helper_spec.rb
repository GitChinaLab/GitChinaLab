# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecaptchaHelper, type: :helper do
  let(:session) { {} }

  before do
    allow(helper).to receive(:session) { session }
  end

  describe '.show_recaptcha_sign_up?' do
    context 'when reCAPTCHA is disabled' do
      it 'returns false' do
        stub_application_setting(recaptcha_enabled: false)

        expect(helper.show_recaptcha_sign_up?).to be_falsey
      end
    end

    context 'when reCAPTCHA is enabled' do
      it 'returns true' do
        stub_application_setting(recaptcha_enabled: true)

        expect(helper.show_recaptcha_sign_up?).to be_truthy
      end
    end
  end
end
