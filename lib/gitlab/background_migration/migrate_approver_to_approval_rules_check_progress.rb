# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class MigrateApproverToApprovalRulesCheckProgress
      def perform
      end
    end
  end
end

Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesCheckProgress.prepend_mod_with('Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesCheckProgress')
