# frozen_string_literal: true

module Ci
  class PipelineSuccessUnlockArtifactsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineBackgroundQueue

    idempotent!

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        break unless pipeline.has_archive_artifacts?

        results = ::Ci::UnlockArtifactsService
          .new(pipeline.project, pipeline.user)
          .execute(pipeline.ci_ref, pipeline)

        log_extra_metadata_on_done(:unlocked_pipelines, results[:unlocked_pipelines])
        log_extra_metadata_on_done(:unlocked_job_artifacts, results[:unlocked_job_artifacts])
      end
    end
  end
end
