# frozen_string_literal: true

if Gitlab::Sherlock.enabled?
  Rails.application.configure do |config|
    config.middleware.use(Gitlab::Sherlock::Middleware)
  end
end
