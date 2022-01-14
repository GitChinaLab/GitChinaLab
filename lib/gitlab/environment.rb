# frozen_string_literal: true

module Gitlab
  module Environment
    def self.hostname
      @hostname ||= ENV['HOSTNAME'] || Socket.gethostname
    end
  end
end
