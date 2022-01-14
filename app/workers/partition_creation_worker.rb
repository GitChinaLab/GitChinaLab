# frozen_string_literal: true

class PartitionCreationWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :database
  idempotent!

  def perform
    # This worker has been removed in favor of Database::PartitionManagementWorker
    Database::PartitionManagementWorker.new.perform
  end
end
