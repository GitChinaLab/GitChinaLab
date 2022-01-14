# frozen_string_literal: true

module PackagesAccess
  extend ActiveSupport::Concern

  included do
    before_action :verify_packages_enabled!
    before_action :verify_read_package!
  end

  private

  def verify_packages_enabled!
    render_404 unless Gitlab.config.packages.enabled
  end

  def verify_read_package!
    authorize_read_package!(project)
  end
end
