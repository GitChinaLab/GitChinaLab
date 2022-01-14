# frozen_string_literal: true

module Ci
  class UnlockArtifactsService < ::BaseService
    BATCH_SIZE = 100

    def execute(ci_ref, before_pipeline = nil)
      results = {
        unlocked_pipelines: 0,
        unlocked_job_artifacts: 0
      }

      if ::Feature.enabled?(:ci_update_unlocked_job_artifacts, ci_ref.project)
        loop do
          unlocked_pipelines = []
          unlocked_job_artifacts = []

          ::Ci::Pipeline.transaction do
            unlocked_pipelines = unlock_pipelines(ci_ref, before_pipeline)
            unlocked_job_artifacts = unlock_job_artifacts(unlocked_pipelines)
          end

          break if unlocked_pipelines.empty?

          results[:unlocked_pipelines] += unlocked_pipelines.length
          results[:unlocked_job_artifacts] += unlocked_job_artifacts.length
        end
      else
        query = <<~SQL.squish
          UPDATE "ci_pipelines"
          SET    "locked" = #{::Ci::Pipeline.lockeds[:unlocked]}
          WHERE  "ci_pipelines"."id" in (
              #{collect_pipelines(ci_ref, before_pipeline).select(:id).to_sql}
              LIMIT  #{BATCH_SIZE}
              FOR  UPDATE SKIP LOCKED
          )
          RETURNING "ci_pipelines"."id";
        SQL

        loop do
          unlocked_pipelines = Ci::Pipeline.connection.exec_query(query)

          break if unlocked_pipelines.empty?

          results[:unlocked_pipelines] += unlocked_pipelines.length
        end
      end

      results
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def unlock_job_artifacts_query(pipeline_ids)
      ci_job_artifacts = ::Ci::JobArtifact.arel_table

      build_ids = ::Ci::Build.select(:id).where(commit_id: pipeline_ids)

      returning = Arel::Nodes::Grouping.new(ci_job_artifacts[:id])

      Arel::UpdateManager.new
        .table(ci_job_artifacts)
        .where(ci_job_artifacts[:job_id].in(Arel.sql(build_ids.to_sql)))
        .set([[ci_job_artifacts[:locked], ::Ci::JobArtifact.lockeds[:unlocked]]])
        .to_sql + " RETURNING #{returning.to_sql}"
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def unlock_pipelines_query(ci_ref, before_pipeline)
      ci_pipelines = ::Ci::Pipeline.arel_table

      pipelines_scope = ci_ref.pipelines.artifacts_locked
      pipelines_scope = pipelines_scope.before_pipeline(before_pipeline) if before_pipeline
      pipelines_scope = pipelines_scope.select(:id).limit(BATCH_SIZE).lock('FOR UPDATE SKIP LOCKED')

      returning = Arel::Nodes::Grouping.new(ci_pipelines[:id])

      Arel::UpdateManager.new
        .table(ci_pipelines)
        .where(ci_pipelines[:id].in(Arel.sql(pipelines_scope.to_sql)))
        .set([[ci_pipelines[:locked], ::Ci::Pipeline.lockeds[:unlocked]]])
        .to_sql + " RETURNING #{returning.to_sql}"
    end
    # rubocop:enable CodeReuse/ActiveRecord

    private

    def collect_pipelines(ci_ref, before_pipeline)
      pipeline_scope = ci_ref.pipelines
      pipeline_scope = pipeline_scope.before_pipeline(before_pipeline) if before_pipeline

      pipeline_scope.artifacts_locked
    end

    def unlock_job_artifacts(pipelines)
      return if pipelines.empty?

      ::Ci::JobArtifact.connection.exec_query(
        unlock_job_artifacts_query(pipelines.rows.flatten)
      )
    end

    def unlock_pipelines(ci_ref, before_pipeline)
      ::Ci::Pipeline.connection.exec_query(unlock_pipelines_query(ci_ref, before_pipeline))
    end
  end
end
