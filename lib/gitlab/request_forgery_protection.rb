# frozen_string_literal: true

# A module to check CSRF tokens in requests.
# It's used in API helpers and OmniAuth.
# Usage: GitLab::RequestForgeryProtection.call(env)

module Gitlab
  module RequestForgeryProtection
    class Controller < ActionController::Base
      protect_from_forgery with: :exception, prepend: true

      def index
        head :ok
      end
    end

    def self.app
      @app ||= Controller.action(:index)
    end

    def self.call(env)
      app.call(env)
    end

    def self.verified?(env)
      minimal_env = env.slice('REQUEST_METHOD', 'rack.session', 'HTTP_X_CSRF_TOKEN')
                      .merge('rack.input' => '')
      call(minimal_env)

      true
    rescue ActionController::InvalidAuthenticityToken
      false
    end
  end
end
