# frozen_string_literal: true

require 'snowplow-tracker'

module Gitlab
  module Tracking
    module Destinations
      class Snowplow < Base
        extend ::Gitlab::Utils::Override

        SNOWPLOW_NAMESPACE = 'gl'

        override :event
        def event(category, action, label: nil, property: nil, value: nil, context: nil)
          return unless enabled?

          tracker.track_struct_event(category, action, label, property, value, context, (Time.now.to_f * 1000).to_i)
          increment_total_events_counter
        end

        def options(group)
          additional_features = Feature.enabled?(:additional_snowplow_tracking, group, type: :ops)
          {
            namespace: SNOWPLOW_NAMESPACE,
            hostname: hostname,
            cookie_domain: cookie_domain,
            app_id: app_id,
            form_tracking: additional_features,
            link_click_tracking: additional_features
          }.transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
        end

        def enabled?
          Gitlab::CurrentSettings.snowplow_enabled?
        end

        def hostname
          Gitlab::CurrentSettings.snowplow_collector_hostname
        end

        private

        def app_id
          Gitlab::CurrentSettings.snowplow_app_id
        end

        def protocol
          'https'
        end

        def cookie_domain
          Gitlab::CurrentSettings.snowplow_cookie_domain
        end

        def tracker
          @tracker ||= SnowplowTracker::Tracker.new(
            emitter,
            SnowplowTracker::Subject.new,
            SNOWPLOW_NAMESPACE,
            app_id
          )
        end

        def emitter
          SnowplowTracker::AsyncEmitter.new(
            hostname,
            protocol: protocol,
            on_success: method(:increment_successful_events_emissions),
            on_failure: method(:failure_callback)
          )
        end

        def failure_callback(success_count, failures)
          increment_successful_events_emissions(success_count)
          increment_failed_events_emissions(failures.size)
          log_failures(failures)
        end

        def increment_failed_events_emissions(value)
          Gitlab::Metrics.counter(
            :gitlab_snowplow_failed_events_total,
            'Number of failed Snowplow events emissions'
          ).increment({}, value.to_i)
        end

        def increment_successful_events_emissions(value)
          Gitlab::Metrics.counter(
            :gitlab_snowplow_successful_events_total,
            'Number of successful Snowplow events emissions'
          ).increment({}, value.to_i)
        end

        def increment_total_events_counter
          Gitlab::Metrics.counter(
            :gitlab_snowplow_events_total,
            'Number of Snowplow events'
          ).increment
        end

        def log_failures(failures)
          failures.each do |failure|
            Gitlab::AppLogger.error("#{failure["se_ca"]} #{failure["se_ac"]} failed to be reported to collector at #{hostname}")
          end
        end
      end
    end
  end
end
