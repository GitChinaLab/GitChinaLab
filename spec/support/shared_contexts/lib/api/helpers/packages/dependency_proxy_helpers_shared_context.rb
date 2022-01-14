# frozen_string_literal: true

RSpec.shared_context 'dependency proxy helpers context' do
  def allow_fetch_application_setting(attribute:, return_value:)
    attributes = double
    allow(::Gitlab::CurrentSettings.current_application_settings).to receive(:attributes).and_return(attributes)
    allow(attributes).to receive(:fetch).with(attribute, false).and_return(return_value)
  end
end
