# frozen_string_literal: true

module Ci
  module PipelineArtifacts
    class ExpireArtifactsWorker
      include ApplicationWorker

      data_consistency :always

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      deduplicate :until_executed, including_scheduled: true
      idempotent!
      feature_category :build_artifacts

      def perform
        service = ::Ci::PipelineArtifacts::DestroyAllExpiredService.new
        artifacts_count = service.execute
        log_extra_metadata_on_done(:destroyed_pipeline_artifacts_count, artifacts_count)
      end
    end
  end
end
