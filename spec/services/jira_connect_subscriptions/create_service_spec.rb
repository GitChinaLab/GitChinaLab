# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectSubscriptions::CreateService do
  let(:installation) { create(:jira_connect_installation) }
  let(:current_user) { create(:user) }
  let(:group) { create(:group) }
  let(:path) { group.full_path }
  let(:params) { { namespace_path: path, jira_user: jira_user } }
  let(:jira_user) { double(:JiraUser, site_admin?: true) }

  subject { described_class.new(installation, current_user, params).execute }

  before do
    group.add_maintainer(current_user)
  end

  shared_examples 'a failed execution' do
    it 'does not create a subscription' do
      expect { subject }.not_to change { installation.subscriptions.count }
    end

    it 'returns an error status' do
      expect(subject[:status]).to eq(:error)
    end
  end

  context 'remote user does not have access' do
    let(:jira_user) { double(site_admin?: false) }

    it 'does not create a subscription' do
      expect { subject }.not_to change { installation.subscriptions.count }
    end

    it 'returns error' do
      expect(subject[:status]).to eq(:error)
    end
  end

  context 'remote user cannot be retrieved' do
    let(:jira_user) { nil }

    it 'does not create a subscription' do
      expect { subject }.not_to change { installation.subscriptions.count }
    end

    it 'returns error' do
      expect(subject[:status]).to eq(:error)
    end
  end

  context 'when user does have access' do
    it 'creates a subscription' do
      expect { subject }.to change { installation.subscriptions.count }.from(0).to(1)
    end

    it 'returns success' do
      expect(subject[:status]).to eq(:success)
    end

    context 'namespace has projects' do
      let!(:project_1) { create(:project, group: group) }
      let!(:project_2) { create(:project, group: group) }

      before do
        stub_const("#{described_class}::MERGE_REQUEST_SYNC_BATCH_SIZE", 1)
      end

      it 'starts workers to sync projects in batches with delay' do
        allow(Atlassian::JiraConnect::Client).to receive(:generate_update_sequence_id).and_return(123)

        expect(JiraConnect::SyncProjectWorker).to receive(:bulk_perform_in).with(1.minute, [[project_1.id, 123]])
        expect(JiraConnect::SyncProjectWorker).to receive(:bulk_perform_in).with(2.minutes, [[project_2.id, 123]])

        subject
      end
    end
  end

  context 'when path is invalid' do
    let(:path) { 'some_invalid_namespace_path' }

    it_behaves_like 'a failed execution'
  end

  context 'when user does not have access' do
    subject { described_class.new(installation, create(:user), namespace_path: path).execute }

    it_behaves_like 'a failed execution'
  end
end
