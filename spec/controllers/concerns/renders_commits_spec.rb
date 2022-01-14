# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RendersCommits do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:user) { create(:user) }

  controller(ApplicationController) do
    # `described_class` is not available in this context
    include RendersCommits

    def index
      @merge_request = MergeRequest.find(params[:id])
      @commits = set_commits_for_rendering(
        @merge_request.recent_commits.with_latest_pipeline(@merge_request.source_branch),
          commits_count: @merge_request.commits_count
      )

      render json: { html: view_to_html_string('projects/merge_requests/_commits') }
    end
  end

  before do
    sign_in(user)
  end

  def go
    get :index, params: { id: merge_request.id }
  end

  it 'sets instance variables for counts' do
    stub_const("MergeRequestDiff::COMMITS_SAFE_SIZE", 10)

    go

    expect(assigns[:total_commit_count]).to eq(29)
    expect(assigns[:hidden_commit_count]).to eq(19)
    expect(assigns[:commits].size).to eq(10)
  end

  context 'rendering commits' do
    render_views

    it 'avoids N + 1' do
      stub_const("MergeRequestDiff::COMMITS_SAFE_SIZE", 5)

      control_count = ActiveRecord::QueryRecorder.new do
        go
      end.count

      stub_const("MergeRequestDiff::COMMITS_SAFE_SIZE", 15)

      expect do
        go
      end.not_to exceed_all_query_limit(control_count)
    end
  end

  describe '.prepare_commits_for_rendering' do
    it 'avoids N+1' do
      control = ActiveRecord::QueryRecorder.new do
        subject.prepare_commits_for_rendering(merge_request.commits.take(1))
      end

      # Populate Banzai::Filter::References::ReferenceCache
      subject.prepare_commits_for_rendering(merge_request.commits)

      # Reset lazy_latest_pipeline cache to simulate a new request
      BatchLoader::Executor.clear_current

      expect do
        subject.prepare_commits_for_rendering(merge_request.commits)
        merge_request.commits.each(&:latest_pipeline)
      end.not_to exceed_all_query_limit(control.count)
    end
  end
end
