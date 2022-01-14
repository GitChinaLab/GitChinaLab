# frozen_string_literal: true

require_relative 'helpers/test_env'

RSpec.configure do |config|
  config.before(:each, :praefect) do
    allow(Gitlab.config.repositories.storages['default']).to receive(:[]).and_call_original
    allow(Gitlab.config.repositories.storages['default']).to receive(:[]).with('gitaly_address')
      .and_return(TestEnv.praefect_socket_path)
  end
end
