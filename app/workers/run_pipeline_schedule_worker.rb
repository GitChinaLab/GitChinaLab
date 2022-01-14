# frozen_string_literal: true

class RunPipelineScheduleWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_creation
  feature_category :continuous_integration

  def perform(schedule_id, user_id)
    schedule = Ci::PipelineSchedule.find_by_id(schedule_id)
    user = User.find_by_id(user_id)

    return unless schedule && user

    run_pipeline_schedule(schedule, user)
  end

  def run_pipeline_schedule(schedule, user)
    Ci::CreatePipelineService.new(schedule.project,
                                  user,
                                  ref: schedule.ref)
      .execute!(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
  rescue Ci::CreatePipelineService::CreateError => e
    # This is a user operation error such as corrupted .gitlab-ci.yml. Log the error for debugging purpose.
    log_extra_metadata_on_done(:pipeline_creation_error, e)
  rescue StandardError => e
    error(schedule, e)
  end

  private

  def error(schedule, error)
    failed_creation_counter.increment
    log_error(schedule, error)
    track_error(schedule, error)
  end

  def log_error(schedule, error)
    Gitlab::AppLogger.error "Failed to create a scheduled pipeline. " \
                       "schedule_id: #{schedule.id} message: #{error.message}"
  end

  def track_error(schedule, error)
    Gitlab::ErrorTracking
      .track_and_raise_for_dev_exception(error,
                       issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/41231',
                       schedule_id: schedule.id)
  end

  def failed_creation_counter
    @failed_creation_counter ||=
      Gitlab::Metrics.counter(:pipeline_schedule_creation_failed_total,
                              "Counter of failed attempts of pipeline schedule creation")
  end
end
