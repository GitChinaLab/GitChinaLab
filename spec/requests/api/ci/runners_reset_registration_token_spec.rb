# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runners do
  subject { post api("#{prefix}/runners/reset_registration_token", user) }

  shared_examples 'bad request' do |result|
    it 'returns 400 error' do
      expect { subject }.not_to change { get_token }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response).to eq(result)
    end
  end

  shared_examples 'unauthenticated' do
    it 'returns 401 error' do
      expect { subject }.not_to change { get_token }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples 'unauthorized' do
    it 'returns 403 error' do
      expect { subject }.not_to change { get_token }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  shared_examples 'not found' do |scope|
    it 'returns 404 error' do
      expect { subject }.not_to change { get_token }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response).to eq({ 'message' => "404 #{scope.capitalize} Not Found" })
    end
  end

  shared_context 'when unauthorized' do |scope|
    context 'when unauthorized' do
      let_it_be(:user) { create(:user) }

      context "when not a #{scope} member" do
        it_behaves_like 'not found', scope
      end

      context "with a non-admin #{scope} member" do
        before do
          target.add_developer(user)
        end

        it_behaves_like 'unauthorized'
      end
    end
  end

  shared_context 'when authorized' do |scope|
    it 'resets runner registration token' do
      expect { subject }.to change { get_token }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response).to eq({ 'token' => get_token })
    end

    if scope != 'instance'
      context 'when malformed id is provided' do
        let(:prefix) { "/#{scope.pluralize}/some%20string" }

        it_behaves_like 'not found', scope
      end
    end
  end

  describe '/api/v4/runners/reset_registration_token' do
    describe 'POST /api/v4/runners/reset_registration_token' do
      before do
        ApplicationSetting.create_from_defaults
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      end

      let(:prefix) { '' }

      context 'when unauthenticated' do
        let(:user) { nil }

        it_behaves_like 'unauthenticated'
      end

      context 'when unauthorized' do
        let(:user) { create(:user) }

        context "with a non-admin instance member" do
          it_behaves_like 'unauthorized'
        end
      end

      include_context 'when authorized', 'instance' do
        let_it_be(:user) { create(:user, :admin) }

        def get_token
          ApplicationSetting.current_without_cache.runners_registration_token
        end
      end
    end
  end

  describe '/api/v4/groups/:id/runners/reset_registration_token' do
    describe 'POST /api/v4/groups/:id/runners/reset_registration_token' do
      let_it_be(:group) { create_default(:group, :private) }

      let(:prefix) { "/groups/#{group.id}" }

      include_context 'when unauthorized', 'group' do
        let(:target) { group }
      end

      include_context 'when authorized', 'group' do
        let_it_be(:user) { create_default(:group_member, :owner, user: create(:user), group: group ).user }

        def get_token
          group.reload.runners_token
        end
      end
    end
  end

  describe '/api/v4/projects/:id/runners/reset_registration_token' do
    describe 'POST /api/v4/projects/:id/runners/reset_registration_token' do
      let_it_be(:project) { create_default(:project) }

      let(:prefix) { "/projects/#{project.id}" }

      include_context 'when unauthorized', 'project' do
        let(:target) { project }
      end

      include_context 'when authorized', 'project' do
        let_it_be(:user) { project.owner }

        def get_token
          project.reload.runners_token
        end
      end
    end
  end
end
