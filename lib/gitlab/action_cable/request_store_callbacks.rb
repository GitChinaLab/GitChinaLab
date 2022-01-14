# frozen_string_literal: true

module Gitlab
  module ActionCable
    module RequestStoreCallbacks
      def self.install
        ::ActionCable::Server::Worker.set_callback :work, :around, &wrapper
        ::ActionCable::Channel::Base.set_callback :subscribe, :around, &wrapper
        ::ActionCable::Channel::Base.set_callback :unsubscribe, :around, &wrapper
      end

      def self.wrapper
        lambda do |_, inner|
          ::Gitlab::WithRequestStore.with_request_store do
            inner.call
          end
        end
      end
    end
  end
end
