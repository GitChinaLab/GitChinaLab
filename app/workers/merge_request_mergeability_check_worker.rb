# frozen_string_literal: true

class MergeRequestMergeabilityCheckWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review
  idempotent!

  def logger
    @logger ||= Sidekiq.logger
  end

  def perform(merge_request_id)
    merge_request = MergeRequest.find_by_id(merge_request_id)

    unless merge_request
      logger.error(worker: self.class.name, message: "Failed to find merge request", merge_request_id: merge_request_id)
      return
    end

    result =
      ::MergeRequests::MergeabilityCheckService
        .new(merge_request)
        .execute(recheck: false, retry_lease: false)

    logger.error(worker: self.class.name, message: "Failed to check mergeability of merge request: #{result.message}", merge_request_id: merge_request_id) if result.error?
  end
end
