# frozen_string_literal: true

module QA
  module Resource
    module Clusters
      class AgentToken < QA::Resource::Base
        attribute :id
        attribute :secret
        attribute :agent do
          QA::Resource::Clusters::Agent.fabricate_via_api!
        end

        def fabricate!
          puts 'TODO: FABRICATE VIA UI'
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          "gid://gitlab/Clusters::AgentToken/#{id}"
        end

        def api_post_path
          "/graphql"
        end

        def api_post_body
          <<~GQL
          mutation createToken {
            clusterAgentTokenCreate(input: { clusterAgentId: "gid://gitlab/Clusters::Agent/#{agent.id}" name: "token-#{agent.id}" }) {
              secret # This is the value you need to use on the next step
              token {
                createdAt
                id
              }
              errors
            }
          }
          GQL
        end
      end
    end
  end
end
