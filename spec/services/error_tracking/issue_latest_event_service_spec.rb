# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::IssueLatestEventService do
  include_context 'sentry error tracking context'

  let(:params) { {} }

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with authorized user' do
      context 'when issue_latest_event returns an error event' do
        let(:error_event) { build(:error_tracking_sentry_error_event) }

        before do
          expect(error_tracking_setting)
            .to receive(:issue_latest_event).and_return(latest_event: error_event)
        end

        it 'returns the error event' do
          expect(result).to eq(status: :success, latest_event: error_event)
        end
      end

      include_examples 'error tracking service data not ready', :issue_latest_event
      include_examples 'error tracking service sentry error handling', :issue_latest_event
      include_examples 'error tracking service http status handling', :issue_latest_event

      context 'integrated error tracking' do
        let_it_be(:error) { create(:error_tracking_error, project: project) }
        let_it_be(:event) { create(:error_tracking_error_event, error: error) }

        let(:params) { { issue_id: error.id } }

        before do
          error_tracking_setting.update!(integrated: true)
        end

        it 'returns the latest event in expected format' do
          expect(result[:status]).to eq(:success)
          expect(result[:latest_event].to_json).to eq(event.to_sentry_error_event.to_json)
        end
      end
    end

    include_examples 'error tracking service unauthorized user'
    include_examples 'error tracking service disabled'
  end
end
