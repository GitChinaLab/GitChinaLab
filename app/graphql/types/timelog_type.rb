# frozen_string_literal: true

module Types
  class TimelogType < BaseObject
    graphql_name 'Timelog'

    authorize :read_issue

    field :spent_at,
          Types::TimeType,
          null: true,
          description: 'Timestamp of when the time tracked was spent at.'

    field :time_spent,
          GraphQL::Types::Int,
          null: false,
          description: 'Time spent displayed in seconds.'

    field :user,
          Types::UserType,
          null: false,
          description: 'User that logged the time.'

    field :issue,
          Types::IssueType,
          null: true,
          description: 'Issue that logged time was added to.'

    field :merge_request,
          Types::MergeRequestType,
          null: true,
          description: 'Merge request that logged time was added to.'

    field :note,
          Types::Notes::NoteType,
          null: true,
          description: 'Note where the quick action was executed to add the logged time.'

    field :summary, GraphQL::Types::String,
          null: true,
          description: 'Summary of how the time was spent.'

    def user
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.user_id).find
    end

    def issue
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Issue, object.issue_id).find
    end

    def spent_at
      object.spent_at || object.created_at
    end
  end
end
