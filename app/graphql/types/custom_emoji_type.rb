# frozen_string_literal: true

module Types
  class CustomEmojiType < BaseObject
    graphql_name 'CustomEmoji'
    description 'A custom emoji uploaded by user'

    authorize :read_custom_emoji

    field :id, ::Types::GlobalIDType[::CustomEmoji],
          null: false,
          description: 'ID of the emoji.'

    field :name, GraphQL::Types::String,
          null: false,
          description: 'Name of the emoji.'

    field :url, GraphQL::Types::String,
          null: false,
          method: :file,
          description: 'Link to file of the emoji.'

    field :external, GraphQL::Types::Boolean,
          null: false,
          description: 'Whether the emoji is an external link.'
  end
end
