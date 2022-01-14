# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests Context Commit Diffs' do
  let_it_be(:sha1) { "33f3729a45c02fc67d00adb1b8bca394b0e761d9" }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
  let_it_be(:merge_request_context_commit) { create(:merge_request_context_commit, merge_request: merge_request, sha: sha1) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET diffs_batch' do
    let(:headers) { {} }

    shared_examples_for 'serializes diffs with expected arguments' do
      it 'serializes paginated merge request diff collection' do
        expect_next_instance_of(PaginatedDiffSerializer) do |instance|
          expect(instance).to receive(:represent)
            .with(an_instance_of(collection), expected_options)
            .and_call_original
        end

        subject
      end
    end

    def collection_arguments(pagination_data = {})
      {
        environment: nil,
        merge_request: merge_request,
        commit: nil,
        diff_view: :inline,
        merge_ref_head_diff: nil,
        allow_tree_conflicts: true,
        pagination_data: {
          total_pages: nil
        }.merge(pagination_data)
      }
    end

    def go(extra_params = {})
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        only_context_commits: true,
        page: 0,
        per_page: 20,
        format: 'json'
      }

      get diffs_batch_namespace_project_json_merge_request_path(params.merge(extra_params)), headers: headers
    end

    context 'with caching', :use_clean_rails_memory_store_caching do
      subject { go(page: 0, per_page: 5) }

      context 'when the request has not been cached' do
        it_behaves_like 'serializes diffs with expected arguments' do
          let(:collection) { Gitlab::Diff::FileCollection::Compare }
          let(:expected_options) { collection_arguments }
        end
      end

      context 'when the request has already been cached' do
        before do
          go(page: 0, per_page: 5)
        end

        it 'does not serialize diffs' do
          expect_next_instance_of(PaginatedDiffSerializer) do |instance|
            expect(instance).not_to receive(:represent)
          end

          subject
        end

        context 'with the different user' do
          let(:another_user) { create(:user) }

          before do
            project.add_maintainer(another_user)
            sign_in(another_user)
          end

          it_behaves_like 'serializes diffs with expected arguments' do
            let(:collection) { Gitlab::Diff::FileCollection::Compare }
            let(:expected_options) { collection_arguments }
          end
        end
      end
    end
  end
end
