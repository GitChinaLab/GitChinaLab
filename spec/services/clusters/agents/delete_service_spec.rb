# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::DeleteService do
  subject(:service) { described_class.new(container: project, current_user: user) }

  let(:cluster_agent) { create(:cluster_agent) }
  let(:project) { cluster_agent.project }
  let(:user) { create(:user) }

  describe '#execute' do
    context 'without user permissions' do
      it 'fails to delete when the user has no permissions', :aggregate_failures do
        response = service.execute(cluster_agent)

        expect(response.status).to eq(:error)
        expect(response.message).to eq('You have insufficient permissions to delete this cluster agent')

        expect { cluster_agent.reload }.not_to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with user permissions' do
      before do
        project.add_maintainer(user)
      end

      it 'deletes a cluster agent', :aggregate_failures do
        expect { service.execute(cluster_agent) }.to change { ::Clusters::Agent.count }.by(-1)
        expect { cluster_agent.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
