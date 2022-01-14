# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Clusters::AgentAuthorization do
  subject { described_class.new(authorization).as_json }

  shared_examples 'generic authorization' do
    it 'includes shared fields' do
      expect(subject).to include(
        id: authorization.agent_id,
        config_project: a_hash_including(id: authorization.agent.project_id),
        configuration: authorization.config
      )
    end
  end

  context 'project authorization' do
    let(:authorization) { create(:agent_project_authorization) }

    include_examples 'generic authorization'
  end

  context 'group authorization' do
    let(:authorization) { create(:agent_group_authorization) }

    include_examples 'generic authorization'
  end

  context 'implicit authorization' do
    let(:agent) { create(:cluster_agent) }
    let(:authorization) { Clusters::Agents::ImplicitAuthorization.new(agent: agent) }

    include_examples 'generic authorization'
  end
end
