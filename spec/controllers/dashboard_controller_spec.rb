# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardController do
  context 'signed in' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    describe 'GET issues' do
      it_behaves_like 'issuables list meta-data', :issue, :issues
      it_behaves_like 'issuables requiring filter', :issues
    end

    describe 'GET merge requests' do
      it_behaves_like 'issuables list meta-data', :merge_request, :merge_requests
      it_behaves_like 'issuables requiring filter', :merge_requests
    end
  end

  describe "GET activity as JSON" do
    include DesignManagementTestHelpers
    render_views

    let(:user) { create(:user) }
    let(:project) { create(:project, :public, issues_access_level: ProjectFeature::PRIVATE) }
    let(:other_project) { create(:project, :public) }

    before do
      enable_design_management
      create(:event, :created, project: project, target: create(:issue))
      create(:wiki_page_event, :created, project: project)
      create(:wiki_page_event, :updated, project: project)
      create(:design_event, project: project)
      create(:design_event, author: user, project: other_project)

      sign_in(user)

      request.cookies[:event_filter] = 'all'
    end

    context 'when user has permission to see the event' do
      before do
        project.add_developer(user)
        other_project.add_developer(user)
      end

      it 'returns count' do
        get :activity, params: { format: :json }

        expect(json_response['count']).to eq(6)
      end
    end

    context 'when user has no permission to see the event' do
      it 'filters out invisible event' do
        get :activity, params: { format: :json }

        expect(json_response['html']).to include(_('No activities found'))
      end

      it 'filters out invisible event when calculating the count' do
        get :activity, params: { format: :json }

        expect(json_response['count']).to eq(0)
      end
    end
  end

  describe "#check_filters_presence!" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
      get :merge_requests, params: params
    end

    context "no filters" do
      let(:params) { {} }

      it 'sets @no_filters_set to false' do
        expect(assigns[:no_filters_set]).to eq(true)
      end
    end

    context "scalar filters" do
      let(:params) { { author_id: user.id } }

      it 'sets @no_filters_set to false' do
        expect(assigns[:no_filters_set]).to eq(false)
      end
    end

    context "array filters" do
      let(:params) { { label_name: ['bug'] } }

      it 'sets @no_filters_set to false' do
        expect(assigns[:no_filters_set]).to eq(false)
      end
    end
  end
end
