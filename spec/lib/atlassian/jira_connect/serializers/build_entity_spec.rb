# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::BuildEntity do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:project) { create_default(:project) }

  subject { described_class.represent(pipeline) }

  context 'when the pipeline does not belong to any Jira issue' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    describe '#issue_keys' do
      it 'is empty' do
        expect(subject.issue_keys).to be_empty
      end
    end

    describe '#to_json' do
      it 'can encode the object' do
        expect(subject.to_json).to be_valid_json
      end

      it 'is invalid, since it has no issue keys' do
        expect(subject.to_json).not_to match_schema(Atlassian::Schemata.build_info)
      end
    end
  end

  context 'when the pipeline does belong to a Jira issue' do
    let(:pipeline) { create(:ci_pipeline, merge_request: merge_request) }

    %i[jira_branch jira_title].each do |trait|
      context "because it belongs to an MR with a #{trait}" do
        let(:merge_request) { create(:merge_request, trait) }

        describe '#issue_keys' do
          it 'is not empty' do
            expect(subject.issue_keys).not_to be_empty
          end
        end

        describe '#to_json' do
          it 'is valid according to the build info schema' do
            expect(subject.to_json).to be_valid_json.and match_schema(Atlassian::Schemata.build_info)
          end
        end
      end
    end
  end
end
