# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnersResolver < BaseResolver
      include LooksAhead

      type Types::Ci::RunnerType.connection_type, null: true

      argument :active, ::GraphQL::Types::Boolean,
               required: false,
               description: 'Filter runners by active (true) or paused (false) status.'

      argument :status, ::Types::Ci::RunnerStatusEnum,
               required: false,
               description: 'Filter runners by status.'

      argument :type, ::Types::Ci::RunnerTypeEnum,
               required: false,
               description: 'Filter runners by type.'

      argument :tag_list, [GraphQL::Types::String],
               required: false,
               description: 'Filter by tags associated with the runner (comma-separated or array).'

      argument :search, GraphQL::Types::String,
               required: false,
               description: 'Filter by full token or partial text in description field.'

      argument :sort, ::Types::Ci::RunnerSortEnum,
               required: false,
               description: 'Sort order of results.'

      def resolve_with_lookahead(**args)
        apply_lookahead(
          ::Ci::RunnersFinder
            .new(current_user: current_user, params: runners_finder_params(args))
            .execute)
      end

      protected

      def runners_finder_params(params)
        {
          active: params[:active],
          status_status: params[:status]&.to_s,
          type_type: params[:type],
          tag_name: params[:tag_list],
          search: params[:search],
          sort: params[:sort]&.to_s,
          preload: {
            tag_name: node_selection&.selects?(:tag_list)
          }
        }.compact
         .merge(parent_param)
      end

      def parent_param
        return {} unless parent

        raise "Unexpected parent type: #{parent.class}"
      end

      private

      def parent
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end
