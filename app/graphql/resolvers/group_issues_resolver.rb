# frozen_string_literal: true
# rubocop:disable Graphql/ResolverType (inherited from BaseIssuesResolver)

module Resolvers
  class GroupIssuesResolver < BaseIssuesResolver
    include GroupIssuableResolver

    include_subgroups 'issues'

    def ready?(**args)
      if args.dig(:not, :release_tag).present?
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'releaseTag filter is not allowed when parent is a group.'
      end

      super
    end
  end
end
