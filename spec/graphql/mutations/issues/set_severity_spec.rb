# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetSeverity do
  let_it_be(:project) { create(:project) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:issue) { create(:incident, project: project) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_issue, :admin_issue) }

  before_all do
    project.add_guest(guest)
    project.add_reporter(reporter)
  end

  describe '#resolve' do
    let(:severity) { 'critical' }

    subject(:resolve) do
      mutation.resolve(
        project_path: issue.project.full_path,
        iid: issue.iid,
        severity: severity
      )
    end

    context 'as guest' do
      let(:user) { guest }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end

      context 'and also author' do
        let!(:issue) { create(:incident, project: project, author: user) }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'and also assignee' do
        let!(:issue) { create(:incident, project: project, assignee_ids: [user.id]) }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'as reporter' do
      let(:user) { reporter }

      context 'when issue type is incident' do
        context 'when severity has a correct value' do
          it 'updates severity' do
            expect(resolve[:issue].severity).to eq('critical')
          end

          it 'returns no errors' do
            expect(resolve[:errors]).to be_empty
          end
        end

        context 'when severity has an unsuported value' do
          let(:severity) { 'unsupported-severity' }

          it 'sets severity to default' do
            expect(resolve[:issue].severity).to eq(IssuableSeverity::DEFAULT)
          end

          it 'returns no errorsr' do
            expect(resolve[:errors]).to be_empty
          end
        end
      end

      context 'when issue type is not incident' do
        let!(:issue) { create(:issue, project: project) }

        it 'does not update the issue' do
          expect { resolve }.not_to change { issue.updated_at }
        end
      end
    end
  end
end
