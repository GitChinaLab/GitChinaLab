# frozen_string_literal: true

module Types
  module Clusters
    class AgentTokenType < BaseObject
      graphql_name 'ClusterAgentToken'

      authorize :admin_cluster

      connection_type_class(Types::CountableConnectionType)

      field :cluster_agent,
            Types::Clusters::AgentType,
            description: 'Cluster agent this token is associated with.',
            null: true

      field :created_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the token was created.'

      field :created_by_user,
            Types::UserType,
            null: true,
            description: 'User who created the token.'

      field :description,
            GraphQL::Types::String,
            null: true,
            description: 'Description of the token.'

      field :last_used_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the token was last used.'

      field :id,
            ::Types::GlobalIDType[::Clusters::AgentToken],
            null: false,
            description: 'Global ID of the token.'

      field :name,
            GraphQL::Types::String,
            null: true,
            description: 'Name given to the token.'

      def cluster_agent
        Gitlab::Graphql::Loaders::BatchModelLoader.new(::Clusters::Agent, object.agent_id).find
      end
    end
  end
end
