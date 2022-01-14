# frozen_string_literal: true

class PagesTransferWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  TransferFailedError = Class.new(StandardError)

  feature_category :pages
  loggable_arguments 0, 1

  def perform(method, args)
    return unless Gitlab::PagesTransfer::METHODS.include?(method)

    result = Gitlab::PagesTransfer.new.public_send(method, *args) # rubocop:disable GitlabSecurity/PublicSend

    # If result isn't truthy, the move failed. Promote this to an
    # exception so that it will be logged and retried appropriately
    raise TransferFailedError unless result
  end
end
