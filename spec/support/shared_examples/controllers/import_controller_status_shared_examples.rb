# frozen_string_literal: true

RSpec.shared_examples 'import controller status' do
  include ImportSpecHelper

  let(:group) { create(:group) }

  before do
    group.add_owner(user)
  end

  it "returns variables for json request" do
    project = create(:project, import_type: provider_name, creator_id: user.id)
    stub_client(client_repos_field => [repo])

    get :status, format: :json

    expect(response).to have_gitlab_http_status(:ok)
    expect(json_response.dig("imported_projects", 0, "id")).to eq(project.id)
    expect(json_response.dig("provider_repos", 0, "id")).to eq(repo_id)
  end
end
