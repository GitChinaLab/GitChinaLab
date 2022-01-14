# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::LearnGitlabController do
  describe 'GET #index' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: create(:group)) }

    let(:learn_gitlab_enabled) { true }
    let(:params) { { namespace_id: project.namespace.to_param, project_id: project } }

    subject(:action) { get :index, params: params }

    before do
      project.namespace.add_owner(user)
      allow(controller.helpers).to receive(:learn_gitlab_enabled?).and_return(learn_gitlab_enabled)
    end

    context 'unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
    end

    context 'authenticated user' do
      before do
        sign_in(user)
      end

      it { is_expected.to render_template(:index) }

      context 'learn_gitlab experiment not enabled' do
        let(:learn_gitlab_enabled) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      it_behaves_like 'tracks assignment and records the subject', :invite_for_help_continuous_onboarding, :namespace do
        subject { project.namespace }
      end
    end
  end
end
