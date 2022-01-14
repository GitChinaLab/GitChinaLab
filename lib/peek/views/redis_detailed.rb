# frozen_string_literal: true

module Peek
  module Views
    class RedisDetailed < DetailedView
      REDACTED_MARKER = "<redacted>"

      def key
        'redis'
      end

      def detail_store
        ::Gitlab::Instrumentation::Redis.detail_store
      end

      private

      def format_call_details(call)
        super.merge(cmd: format_command(call[:cmd]),
                    instance: call[:storage])
      end

      def format_command(cmd)
        if cmd.length >= 2 && cmd.first =~ /^auth$/i
          cmd[-1] = REDACTED_MARKER
        # Scrub out the value of the SET calls to avoid binary
        # data or large data from spilling into the view
        elsif cmd.length >= 3 && cmd.first =~ /set/i
          cmd[2..-1] = REDACTED_MARKER
        end

        cmd.join(' ')
      end
    end
  end
end
