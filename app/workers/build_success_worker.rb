# frozen_string_literal: true

class BuildSuccessWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include PipelineQueue

  queue_namespace :pipeline_processing
  urgency :high

  def perform(build_id)
    Ci::Build.find_by_id(build_id).try do |build|
      stop_environment(build) if build.stops_environment?
    end
  end

  private

  def stop_environment(build)
    build.persisted_environment.fire_state_event(:stop)
  end
end
