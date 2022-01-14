# frozen_string_literal: true

module Mutations
  class Echo < BaseMutation
    graphql_name 'EchoCreate'
    description <<~DOC
      A mutation that does not perform any changes.

      This is expected to be used for testing of endpoints, to verify
      that a user has mutation access.
    DOC

    argument :errors,
             type: [::GraphQL::Types::String],
             required: false,
             description: 'Errors to return to the user.'

    argument :messages,
             type: [::GraphQL::Types::String],
             as: :echoes,
             required: false,
             description: 'Messages to return to the user.'

    field :echoes,
          type: [::GraphQL::Types::String],
          null: true,
          description: 'Messages returned to the user.'

    def resolve(**args)
      args
    end
  end
end
