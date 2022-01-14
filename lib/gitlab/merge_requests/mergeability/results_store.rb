# frozen_string_literal: true
module Gitlab
  module MergeRequests
    module Mergeability
      class ResultsStore
        def initialize(interface: RedisInterface.new, merge_request:)
          @interface = interface
          @merge_request = merge_request
        end

        def read(merge_check:)
          interface.retrieve_check(merge_check: merge_check)
        end

        def write(merge_check:, result_hash:)
          interface.save_check(merge_check: merge_check, result_hash: result_hash)
        end

        private

        attr_reader :interface
      end
    end
  end
end
