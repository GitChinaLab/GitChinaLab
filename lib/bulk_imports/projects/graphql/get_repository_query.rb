# frozen_string_literal: true

module BulkImports
  module Projects
    module Graphql
      module GetRepositoryQuery
        extend Queryable
        extend self

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!) {
            project(fullPath: $full_path) {
              httpUrlToRepo
            }
          }
          GRAPHQL
        end
      end
    end
  end
end
