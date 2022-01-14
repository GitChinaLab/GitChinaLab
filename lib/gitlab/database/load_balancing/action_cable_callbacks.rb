# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      module ActionCableCallbacks
        def self.install
          ::ActionCable::Server::Worker.set_callback :work, :around, &wrapper
          ::ActionCable::Channel::Base.set_callback :subscribe, :around, &wrapper
          ::ActionCable::Channel::Base.set_callback :unsubscribe, :around, &wrapper
        end

        def self.wrapper
          lambda do |_, inner|
            ::Gitlab::Database::LoadBalancing::Session.current.use_primary!

            inner.call
          ensure
            ::Gitlab::Database::LoadBalancing.release_hosts
            ::Gitlab::Database::LoadBalancing::Session.clear_session
          end
        end
      end
    end
  end
end
