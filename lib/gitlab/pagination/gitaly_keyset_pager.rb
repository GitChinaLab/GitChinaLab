# frozen_string_literal: true

module Gitlab
  module Pagination
    class GitalyKeysetPager
      attr_reader :request_context, :project
      delegate :params, to: :request_context

      def initialize(request_context, project)
        @request_context = request_context
        @project = project
      end

      # It is expected that the given finder will respond to `execute` method with `gitaly_pagination: true` option
      # and supports pagination via gitaly.
      def paginate(finder)
        return paginate_via_gitaly(finder) if keyset_pagination_enabled?(finder)
        return paginate_first_page_via_gitaly(finder) if paginate_first_page?(finder)

        records = ::Kaminari.paginate_array(finder.execute)
        Gitlab::Pagination::OffsetPagination
          .new(request_context)
          .paginate(records)
      end

      private

      def keyset_pagination_enabled?(finder)
        return false unless params[:pagination] == "keyset"

        if finder.is_a?(BranchesFinder)
          Feature.enabled?(:branch_list_keyset_pagination, project, default_enabled: :yaml)
        elsif finder.is_a?(TagsFinder)
          Feature.enabled?(:tag_list_keyset_pagination, project, default_enabled: :yaml)
        elsif finder.is_a?(::Repositories::TreeFinder)
          Feature.enabled?(:repository_tree_gitaly_pagination, project, default_enabled: :yaml)
        else
          false
        end
      end

      def paginate_first_page?(finder)
        return false unless params[:page].blank? || params[:page].to_i == 1

        if finder.is_a?(BranchesFinder)
          Feature.enabled?(:branch_list_keyset_pagination, project, default_enabled: :yaml)
        elsif finder.is_a?(TagsFinder)
          Feature.enabled?(:tag_list_keyset_pagination, project, default_enabled: :yaml)
        elsif finder.is_a?(::Repositories::TreeFinder)
          Feature.enabled?(:repository_tree_gitaly_pagination, project, default_enabled: :yaml)
        else
          false
        end
      end

      def paginate_via_gitaly(finder)
        finder.execute(gitaly_pagination: true).tap do |records|
          apply_headers(records)
        end
      end

      # When first page is requested, we paginate the data via Gitaly
      # Headers are added to immitate offset pagination, while it is the default option
      def paginate_first_page_via_gitaly(finder)
        finder.execute(gitaly_pagination: true).tap do |records|
          total = finder.total
          per_page = params[:per_page].presence || Kaminari.config.default_per_page

          Gitlab::Pagination::OffsetHeaderBuilder.new(
            request_context: request_context, per_page: per_page, page: 1, next_page: 2,
            total: total, total_pages: total / per_page + 1
          ).execute
        end
      end

      def apply_headers(records)
        if records.count == params[:per_page]
          Gitlab::Pagination::Keyset::HeaderBuilder
            .new(request_context)
            .add_next_page_header(
              query_params_for(records.last)
            )
        end
      end

      def query_params_for(record)
        # NOTE: page_token is name for now, but it could be dynamic if we have other gitaly finders
        # that is based on something other than name
        { page_token: record.name }
      end
    end
  end
end
