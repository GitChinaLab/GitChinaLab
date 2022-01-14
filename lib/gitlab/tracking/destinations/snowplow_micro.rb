# frozen_string_literal: true
#
module Gitlab
  module Tracking
    module Destinations
      class SnowplowMicro < Snowplow
        include ::Gitlab::Utils::StrongMemoize
        extend ::Gitlab::Utils::Override

        DEFAULT_URI = 'http://localhost:9090'

        override :options
        def options(group)
          super.update(
            protocol: uri.scheme,
            port: uri.port,
            force_secure_tracker: false
          ).transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
        end

        override :enabled?
        def enabled?
          true
        end

        override :hostname
        def hostname
          "#{uri.host}:#{uri.port}"
        end

        def uri
          strong_memoize(:snowplow_uri) do
            uri = URI(ENV['SNOWPLOW_MICRO_URI'] || DEFAULT_URI)
            uri = URI("http://#{ENV['SNOWPLOW_MICRO_URI']}") unless %w[http https].include?(uri.scheme)
            uri
          end
        end

        private

        override :cookie_domain
        def cookie_domain
          '.gitlab.com'
        end

        override :protocol
        def protocol
          uri.scheme
        end
      end
    end
  end
end
