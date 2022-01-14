# frozen_string_literal: true

class Import::AvailableNamespacesController < ApplicationController
  feature_category :importers

  def index
    render json: NamespaceSerializer.new.represent(current_user.manageable_groups_with_routes(include_groups_with_developer_maintainer_access: true))
  end
end
