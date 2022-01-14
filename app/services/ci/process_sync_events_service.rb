# frozen_string_literal: true

module Ci
  class ProcessSyncEventsService
    include Gitlab::Utils::StrongMemoize
    include ExclusiveLeaseGuard

    BATCH_SIZE = 1000

    def initialize(sync_event_class, sync_class)
      @sync_event_class = sync_event_class
      @sync_class = sync_class
    end

    def execute
      return unless ::Feature.enabled?(:ci_namespace_project_mirrors, default_enabled: :yaml)

      # preventing parallel processing over the same event table
      try_obtain_lease { process_events }

      enqueue_worker_if_there_still_event
    end

    private

    def process_events
      events = @sync_event_class.preload_synced_relation.first(BATCH_SIZE)

      return if events.empty?

      first = events.first
      last_processed = nil

      begin
        events.each do |event|
          @sync_class.sync!(event)

          last_processed = event
        end
      ensure
        # remove events till the one that was last succesfully processed
        @sync_event_class.id_in(first.id..last_processed.id).delete_all if last_processed
      end
    end

    def enqueue_worker_if_there_still_event
      @sync_event_class.enqueue_worker if @sync_event_class.exists?
    end

    def lease_key
      "#{super}::#{@sync_event_class}"
    end

    def lease_timeout
      1.minute
    end
  end
end
