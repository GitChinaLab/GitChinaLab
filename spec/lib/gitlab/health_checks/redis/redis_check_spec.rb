# frozen_string_literal: true

require 'spec_helper'
require_relative '../simple_check_shared'

RSpec.describe Gitlab::HealthChecks::Redis::RedisCheck do
  include_examples 'simple_check', 'redis_ping', 'Redis', true
end
