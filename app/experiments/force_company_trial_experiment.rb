# frozen_string_literal: true

class ForceCompanyTrialExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  exclude :setup_for_personal

  private

  def setup_for_personal
    !context.user.setup_for_company
  end
end
