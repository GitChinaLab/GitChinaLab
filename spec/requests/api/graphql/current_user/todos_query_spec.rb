# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query current user todos' do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:unauthorize_project) { create(:project) }
  let_it_be(:commit_todo) { create(:on_commit_todo, user: current_user, project: project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:issue_todo) { create(:todo, project: project, user: current_user, target: issue) }
  let_it_be(:merge_request_todo) { create(:todo, project: project, user: current_user, target: create(:merge_request, source_project: project)) }
  let_it_be(:design_todo) { create(:todo, project: project, user: current_user, target: create(:design, issue: issue)) }
  let_it_be(:unauthorized_todo) { create(:todo, user: current_user, project: unauthorize_project, target: create(:issue, project: unauthorize_project)) }

  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('todos'.classify)}
    }
    QUERY
  end

  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('todos', {}, fields))
  end

  before_all do
    project.add_developer(current_user)
  end

  subject { graphql_data.dig('currentUser', 'todos', 'nodes') }

  before do
    enable_design_management

    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'contains the expected ids' do
    is_expected.to contain_exactly(
      a_hash_including('id' => commit_todo.to_global_id.to_s),
      a_hash_including('id' => issue_todo.to_global_id.to_s),
      a_hash_including('id' => merge_request_todo.to_global_id.to_s),
      a_hash_including('id' => design_todo.to_global_id.to_s)
    )
  end

  it 'returns Todos for all target types' do
    is_expected.to contain_exactly(
      a_hash_including('targetType' => 'COMMIT'),
      a_hash_including('targetType' => 'ISSUE'),
      a_hash_including('targetType' => 'MERGEREQUEST'),
      a_hash_including('targetType' => 'DESIGN')
    )
  end

  context 'when requesting a single field' do
    let(:fields) do
      <<~QUERY
      nodes {
        id
      }
      QUERY
    end

    it 'avoids N+1 queries', :request_store, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/338671' do
      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }

      project2 = create(:project)
      project2.add_developer(current_user)
      issue2 = create(:issue, project: project2)
      create(:todo, user: current_user, target: issue2, project: project2)

      # An additional query is made for each different group that owns a todo through a project
      expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control).with_threshold(2)
    end
  end
end
