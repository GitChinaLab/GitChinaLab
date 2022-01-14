# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ConfigureSecretDetection' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :test_repo) }

  let(:variables) { { project_path: project.full_path } }
  let(:mutation) { graphql_mutation(:configure_secret_detection, variables) }
  let(:mutation_response) { graphql_mutation_response(:configureSecretDetection) }

  context 'when authorized' do
    let_it_be(:user) { project.owner }

    it 'creates a branch with secret detection configured' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['errors']).to be_empty
      expect(mutation_response['branch']).not_to be_empty
      expect(mutation_response['successPath']).not_to be_empty
    end
  end
end
