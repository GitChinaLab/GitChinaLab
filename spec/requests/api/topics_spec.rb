# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Topics do
  include WorkhorseHelpers

  let_it_be(:file) { fixture_file_upload('spec/fixtures/dk.png') }

  let_it_be(:topic_1) { create(:topic, name: 'Git', total_projects_count: 1, avatar: file) }
  let_it_be(:topic_2) { create(:topic, name: 'GitLab', total_projects_count: 2) }
  let_it_be(:topic_3) { create(:topic, name: 'other-topic', total_projects_count: 3) }

  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:user) { create(:user) }

  describe 'GET /topics', :aggregate_failures do
    it 'returns topics ordered by total_projects_count' do
      get api('/topics')

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.length).to eq(3)

      expect(json_response[0]['id']).to eq(topic_3.id)
      expect(json_response[0]['name']).to eq('other-topic')
      expect(json_response[0]['total_projects_count']).to eq(3)

      expect(json_response[1]['id']).to eq(topic_2.id)
      expect(json_response[1]['name']).to eq('GitLab')
      expect(json_response[1]['total_projects_count']).to eq(2)

      expect(json_response[2]['id']).to eq(topic_1.id)
      expect(json_response[2]['name']).to eq('Git')
      expect(json_response[2]['total_projects_count']).to eq(1)
    end

    context 'with search' do
      using RSpec::Parameterized::TableSyntax

      where(:search, :result) do
        ''    | %w[other-topic GitLab Git]
        'g'   | %w[]
        'gi'  | %w[]
        'git' | %w[Git GitLab]
        'x'   | %w[]
        0     | %w[]
      end

      with_them do
        it 'returns filtered topics' do
          get api('/topics'), params: { search: search }

          expect(json_response.map { |t| t['name'] }).to eq(result)
        end
      end
    end

    context 'with pagination' do
      using RSpec::Parameterized::TableSyntax

      where(:params, :result) do
        { page: 0 }              | %w[other-topic GitLab Git]
        { page: 1 }              | %w[other-topic GitLab Git]
        { page: 2 }              | %w[]
        { per_page: 1 }          | %w[other-topic]
        { per_page: 2 }          | %w[other-topic GitLab]
        { per_page: 3 }          | %w[other-topic GitLab Git]
        { page: 0, per_page: 1 } | %w[other-topic]
        { page: 0, per_page: 2 } | %w[other-topic GitLab]
        { page: 1, per_page: 1 } | %w[other-topic]
        { page: 1, per_page: 2 } | %w[other-topic GitLab]
        { page: 2, per_page: 1 } | %w[GitLab]
        { page: 2, per_page: 2 } | %w[Git]
        { page: 3, per_page: 1 } | %w[Git]
        { page: 3, per_page: 2 } | %w[]
        { page: 4, per_page: 1 } | %w[]
        { page: 4, per_page: 2 } | %w[]
      end

      with_them do
        it 'returns paginated topics' do
          get api('/topics'), params: params

          expect(json_response.map { |t| t['name'] }).to eq(result)
        end
      end
    end
  end

  describe 'GET /topic/:id', :aggregate_failures do
    it 'returns topic' do
      get api("/topics/#{topic_2.id}")

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response['id']).to eq(topic_2.id)
      expect(json_response['name']).to eq('GitLab')
      expect(json_response['total_projects_count']).to eq(2)
    end

    it 'returns 404 for non existing id' do
      get api("/topics/#{non_existing_record_id}")

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 400 for invalid `id` parameter' do
      get api('/topics/invalid')

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eql('id is invalid')
    end
  end

  describe 'POST /topics', :aggregate_failures do
    context 'as administrator' do
      it 'creates a topic' do
        post api('/topics/', admin), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq('my-topic')
        expect(Projects::Topic.find(json_response['id']).name).to eq('my-topic')
      end

      it 'creates a topic with avatar and description' do
        workhorse_form_with_file(
          api('/topics/', admin),
          file_key: :avatar,
          params: { name: 'my-topic', description: 'my description...', avatar: file }
        )

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['description']).to eq('my description...')
        expect(json_response['avatar_url']).to end_with('dk.png')
      end

      it 'returns 400 if name is missing' do
        post api('/topics/', admin)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eql('name is missing')
      end
    end

    context 'as normal user' do
      it 'returns 403 Forbidden' do
        post api('/topics/', user), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'as anonymous' do
      it 'returns 401 Unauthorized' do
        post api('/topics/'), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /topics', :aggregate_failures do
    context 'as administrator' do
      it 'updates a topic' do
        put api("/topics/#{topic_3.id}", admin), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('my-topic')
        expect(topic_3.reload.name).to eq('my-topic')
      end

      it 'updates a topic with avatar and description' do
        workhorse_form_with_file(
          api("/topics/#{topic_3.id}", admin),
          method: :put,
          file_key: :avatar,
          params: { description: 'my description...', avatar: file }
        )

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['description']).to eq('my description...')
        expect(json_response['avatar_url']).to end_with('dk.png')
      end

      it 'keeps avatar when updating other fields' do
        put api("/topics/#{topic_1.id}", admin), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('my-topic')
        expect(topic_1.reload.avatar_url).not_to be_nil
      end

      it 'returns 404 for non existing id' do
        put api("/topics/#{non_existing_record_id}", admin), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 400 for invalid `id` parameter' do
        put api('/topics/invalid', admin), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eql('id is invalid')
      end

      context 'with blank avatar' do
        it 'removes avatar' do
          put api("/topics/#{topic_1.id}", admin), params: { avatar: '' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['avatar_url']).to be_nil
          expect(topic_3.reload.avatar_url).to be_nil
        end

        it 'removes avatar besides other changes' do
          put api("/topics/#{topic_1.id}", admin), params: { name: 'new-topic-name', avatar: '' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['name']).to eq('new-topic-name')
          expect(json_response['avatar_url']).to be_nil
          expect(topic_1.reload.avatar_url).to be_nil
        end

        it 'does not remove avatar in case of other errors' do
          put api("/topics/#{topic_1.id}", admin), params: { name: topic_2.name, avatar: '' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(topic_1.reload.avatar_url).not_to be_nil
        end
      end
    end

    context 'as normal user' do
      it 'returns 403 Forbidden' do
        put api("/topics/#{topic_3.id}", user), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'as anonymous' do
      it 'returns 401 Unauthorized' do
        put api("/topics/#{topic_3.id}"), params: { name: 'my-topic' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
