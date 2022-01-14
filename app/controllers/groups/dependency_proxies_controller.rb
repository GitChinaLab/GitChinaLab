# frozen_string_literal: true

module Groups
  class DependencyProxiesController < Groups::ApplicationController
    include ::DependencyProxy::GroupAccess

    before_action :authorize_admin_dependency_proxy!, only: :update
    before_action :verify_dependency_proxy_enabled!

    feature_category :package_registry

    private

    def dependency_proxy
      @dependency_proxy ||=
        group.dependency_proxy_setting || group.create_dependency_proxy_setting!
    end

    def verify_dependency_proxy_enabled!
      render_404 unless dependency_proxy.enabled?
    end
  end
end
