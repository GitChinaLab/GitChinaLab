# frozen_string_literal: true

module Resolvers
  module FullPathResolver
    extend ActiveSupport::Concern

    prepended do
      argument :full_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project, group, or namespace. For example, `gitlab-org/gitlab-foss`.'
    end

    def model_by_full_path(model, full_path)
      ::Gitlab::Graphql::Loaders::FullPathModelLoader.new(model, full_path).find
    end
  end
end
