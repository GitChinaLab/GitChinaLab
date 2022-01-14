# frozen_string_literal: true

module BulkImports
  module Groups
    module Graphql
      module GetProjectsQuery
        extend self

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!, $cursor: String, $per_page: Int) {
            group(fullPath: $full_path) {
              projects(includeSubgroups: false, first: $per_page, after: $cursor) {
                page_info: pageInfo {
                  next_page: endCursor
                  has_next_page: hasNextPage
                }
                nodes {
                  name
                  full_path: fullPath
                }
              }
            }
          }
          GRAPHQL
        end

        def variables(context)
          {
            full_path: context.entity.source_full_path,
            cursor: context.tracker.next_page,
            per_page: ::BulkImports::Tracker::DEFAULT_PAGE_SIZE
          }
        end

        def base_path
          %w[data group projects]
        end

        def data_path
          base_path << 'nodes'
        end

        def page_info_path
          base_path << 'page_info'
        end
      end
    end
  end
end
