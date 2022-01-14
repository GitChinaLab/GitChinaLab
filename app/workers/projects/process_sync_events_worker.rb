# frozen_string_literal: true

module Projects
  # This worker can be called multiple times at the same time but only one of them can
  # process events at a time. This is ensured by `try_obtain_lease` in `Ci::ProcessSyncEventsService`.
  # `until_executing` here is to reduce redundant worker enqueuing.
  class ProcessSyncEventsWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :sharding
    urgency :high

    idempotent!
    deduplicate :until_executing

    def perform
      ::Ci::ProcessSyncEventsService.new(::Projects::SyncEvent, ::Ci::ProjectMirror).execute
    end
  end
end
