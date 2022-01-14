# frozen_string_literal: true

module Namespaces
  class InProductMarketingEmailsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :experimentation_activation
    urgency :low

    def perform
      return if paid_self_managed_instance?
      return if setting_disabled?

      Namespaces::InProductMarketingEmailsService.send_for_all_tracks_and_intervals
    end

    private

    def paid_self_managed_instance?
      false
    end

    def setting_disabled?
      !Gitlab::CurrentSettings.in_product_marketing_emails_enabled
    end
  end
end

Namespaces::InProductMarketingEmailsWorker.prepend_mod_with('Namespaces::InProductMarketingEmailsWorker')
