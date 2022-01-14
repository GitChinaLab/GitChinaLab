# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActionCableSubscriptionAdapterIdentifier override' do
  describe '#identifier' do
    let!(:original_config) { ::ActionCable::Server::Base.config.cable }

    after do
      ::ActionCable::Server::Base.config.cable = original_config
    end

    context 'when id key is nil on cable.yml' do
      it 'does not override server config id with action cable pid' do
        config = {
          adapter: 'redis',
          url: 'unix:/home/localuser/redis/redis.socket',
          channel_prefix: 'test_',
          id: nil
        }
        ::ActionCable::Server::Base.config.cable = config

        sub = ActionCable.server.pubsub.send(:redis_connection)

        expect(sub.connection[:id]).to eq('redis:///home/localuser/redis/redis.socket/0')
        expect(ActionCable.server.config.cable[:id]).to be_nil
      end
    end
  end
end
