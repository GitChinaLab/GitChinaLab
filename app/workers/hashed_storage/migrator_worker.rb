# frozen_string_literal: true

module HashedStorage
  class MigratorWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :hashed_storage
    feature_category :source_code_management

    # https://gitlab.com/gitlab-org/gitlab/-/issues/340629
    tags :needs_own_queue

    # @param [Integer] start initial ID of the batch
    # @param [Integer] finish last ID of the batch
    def perform(start, finish)
      migrator = Gitlab::HashedStorage::Migrator.new
      migrator.bulk_migrate(start: start, finish: finish)
    end
  end
end
