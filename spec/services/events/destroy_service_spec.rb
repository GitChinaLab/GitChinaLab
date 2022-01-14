# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Events::DestroyService do
  subject(:service) { described_class.new(project) }

  let_it_be(:project, reload: true) { create(:project, :repository) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:user) { create(:user) }

  let!(:unrelated_event) { create(:event, :merged, project: another_project, target: another_project, author: user) }

  before do
    create(:event, :created, project: project, target: project, author: user)
    create(:event, :created, project: project, target: merge_request, author: user)
    create(:event, :merged, project: project, target: merge_request, author: user)
  end

  let(:events) { project.events }

  describe '#execute', :aggregate_failures do
    it 'deletes the events' do
      response = nil

      expect { response = subject.execute }.to change(Event, :count).by(-3)

      expect(response).to be_success
      expect(unrelated_event.reload).to be_present
    end

    context 'when an error is raised while deleting the records' do
      before do
        allow(project).to receive_message_chain(:events, :all, :delete_all).and_raise(ActiveRecord::ActiveRecordError)
      end

      it 'returns error' do
        response = subject.execute

        expect(response).to be_error
        expect(response.message).to eq 'Failed to remove events.'
      end

      it 'does not delete events' do
        expect { subject.execute }.not_to change(Event, :count)
      end
    end
  end
end
