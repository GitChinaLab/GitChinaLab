# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Clusters::AgentTokens::Create do
  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  let_it_be(:cluster_agent) { create(:cluster_agent) }
  let_it_be(:user) { create(:user) }

  let(:context) do
    GraphQL::Query::Context.new(
      query: OpenStruct.new(schema: nil),
      values: { current_user: user },
      object: nil
    )
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_cluster) }

  describe '#resolve' do
    let(:description) { 'new token!' }
    let(:name) { 'new name' }

    subject { mutation.resolve(cluster_agent_id: cluster_agent.to_global_id, description: description, name: name) }

    context 'without token permissions' do
      it 'raises an error if the resource is not accessible to the user' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with user permissions' do
      before do
        cluster_agent.project.add_maintainer(user)
      end

      it 'creates a new token', :aggregate_failures do
        expect { subject }.to change { ::Clusters::AgentToken.count }.by(1)
        expect(subject[:errors]).to eq([])
      end

      it 'returns token information', :aggregate_failures do
        token = subject[:token]

        expect(subject[:secret]).not_to be_nil
        expect(token.created_by_user).to eq(user)
        expect(token.description).to eq(description)
        expect(token.name).to eq(name)
      end

      context 'invalid params' do
        subject { mutation.resolve(cluster_agent_id: cluster_agent.id) }

        it 'generates an error message when id invalid', :aggregate_failures do
          expect { subject }.to raise_error(::GraphQL::CoercionError)
        end
      end
    end
  end
end
