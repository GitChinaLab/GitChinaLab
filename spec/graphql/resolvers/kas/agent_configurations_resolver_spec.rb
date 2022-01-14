# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Kas::AgentConfigurationsResolver do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Kas::AgentConfigurationType) }
  it { expect(described_class.null).to be_truthy }
  it { expect(described_class.field_options).to include(calls_gitaly: true) }

  describe '#resolve' do
    let_it_be(:project) { create(:project) }

    let(:user) { create(:user, maintainer_projects: [project]) }
    let(:ctx) { Hash(current_user: user) }

    let(:agent1) { double }
    let(:agent2) { double }
    let(:kas_client) { instance_double(Gitlab::Kas::Client, list_agent_config_files: [agent1, agent2]) }

    subject { resolve(described_class, obj: project, ctx: ctx) }

    before do
      allow(Gitlab::Kas::Client).to receive(:new).and_return(kas_client)
    end

    it 'returns agents configured for the project' do
      expect(subject).to contain_exactly(agent1, agent2)
    end

    context 'an error is returned from the KAS client' do
      before do
        allow(kas_client).to receive(:list_agent_config_files).and_raise(GRPC::DeadlineExceeded)
      end

      it 'raises a graphql error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'GRPC::DeadlineExceeded')
      end
    end

    context 'user does not have permission' do
      let(:user) { create(:user) }

      it { is_expected.to be_empty }
    end
  end
end
