# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      class WebMockEnable < RuboCop::Cop::Cop
        # This cop checks for `WebMock.disable_net_connect!` usage in specs and
        # replaces it with `webmock_enable!`
        #
        # @example
        #
        #   # bad
        #   WebMock.disable_net_connect!
        #   WebMock.disable_net_connect!(allow_localhost: true)
        #
        #   # good
        #   webmock_enable!

        MESSAGE = 'Use webmock_enable! instead of calling WebMock.disable_net_connect! directly.'

        def_node_matcher :webmock_disable_net_connect?, <<~PATTERN
          (send (const nil? :WebMock) :disable_net_connect! ...)
        PATTERN

        def on_send(node)
          if webmock_disable_net_connect?(node)
            add_offense(node, location: :expression, message: MESSAGE)
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node, 'webmock_enable!')
          end
        end
      end
    end
  end
end
