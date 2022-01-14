# frozen_string_literal: true

RSpec.shared_examples 'an unauthorized API user' do
  it { is_expected.to eq(403) }
end

RSpec.shared_examples 'API user with insufficient permissions' do
  context 'with non member that is the author' do
    before do
      issuable.update!(author: non_member) # an external author can't admin issuable
    end

    it_behaves_like 'an unauthorized API user'
  end
end

RSpec.shared_examples 'time tracking endpoints' do |issuable_name|
  let(:non_member) { create(:user) }

  issuable_collection_name = issuable_name.pluralize

  describe "POST /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/time_estimate" do
    context 'with an unauthorized user' do
      subject { post(api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", non_member), params: { duration: '1w' }) }

      it_behaves_like 'an unauthorized API user'
      it_behaves_like 'API user with insufficient permissions'
    end

    it "sets the time estimate for #{issuable_name}" do
      post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", user), params: { duration: '1w' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['human_time_estimate']).to eq('1w')
    end

    describe 'updating the current estimate' do
      before do
        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", user), params: { duration: '1w' }
      end

      context 'when duration has a bad format' do
        it 'does not modify the original estimate' do
          post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", user), params: { duration: 'foo' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(issuable.reload.human_time_estimate).to eq('1w')
        end
      end

      context 'with a valid duration' do
        it 'updates the estimate' do
          post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_estimate", user), params: { duration: '3w1h' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(issuable.reload.human_time_estimate).to eq('3w 1h')
        end
      end
    end
  end

  describe "POST /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/reset_time_estimate" do
    context 'with an unauthorized user' do
      subject { post(api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/reset_time_estimate", non_member)) }

      it_behaves_like 'an unauthorized API user'
      it_behaves_like 'API user with insufficient permissions'
    end

    it "resets the time estimate for #{issuable_name}" do
      post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/reset_time_estimate", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['time_estimate']).to eq(0)
    end
  end

  describe "POST /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/add_spent_time" do
    context 'with an unauthorized user' do
      subject do
        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", non_member), params: { duration: '2h' }
      end

      it_behaves_like 'an unauthorized API user'
      it_behaves_like 'API user with insufficient permissions'
    end

    it "add spent time for #{issuable_name}" do
      Timecop.travel(1.minute.from_now) do
        expect do
          post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", user), params: { duration: '2h' }
        end.to change { issuable.reload.updated_at }
      end

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['human_total_time_spent']).to eq('2h')
    end

    context 'when subtracting time' do
      it 'subtracts time of the total spent time' do
        Timecop.travel(1.minute.from_now) do
          expect do
            issuable.update!(spend_time: { duration: 7200, user_id: user.id })
          end.to change { issuable.reload.updated_at }
        end

        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", user), params: { duration: '-1h' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['total_time_spent']).to eq(3600)
      end
    end

    context 'when time to subtract is greater than the total spent time' do
      it 'does not modify the total time spent' do
        issuable.update!(spend_time: { duration: 7200, user_id: user.id })

        Timecop.travel(1.minute.from_now) do
          expect do
            post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", user), params: { duration: '-1w' }
          end.not_to change { issuable.reload.updated_at }
        end

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['base'].first).to eq(_('Time to subtract exceeds the total time spent'))
      end
    end

    if issuable_name == 'merge_request'
      it 'calls update service with :use_specialized_service param' do
        expect(::MergeRequests::UpdateService).to receive(:new).with(
          project: project,
          current_user: user,
          params: hash_including(
            use_specialized_service: true,
            spend_time: hash_including(duration: 7200, summary: 'summary')))

        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", user), params: { duration: '2h', summary: 'summary' }
      end
    end

    if issuable_name == 'issue'
      it 'calls update service without :use_specialized_service param' do
        expect(::Issues::UpdateService).to receive(:new).with(
          project: project,
          current_user: user,
          params: { spend_time: { duration: 3600, summary: 'summary', user_id: user.id } })

        post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/add_spent_time", user), params: { duration: '1h', summary: 'summary' }
      end
    end
  end

  describe "POST /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/reset_spent_time" do
    context 'with an unauthorized user' do
      subject { post(api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/reset_spent_time", non_member)) }

      it_behaves_like 'an unauthorized API user'
      it_behaves_like 'API user with insufficient permissions'
    end

    it "resets spent time for #{issuable_name}" do
      Timecop.travel(1.minute.from_now) do
        expect do
          post api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/reset_spent_time", user)
        end.to change { issuable.reload.updated_at }
      end

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['total_time_spent']).to eq(0)
    end
  end

  describe "GET /projects/:id/#{issuable_collection_name}/:#{issuable_name}_id/time_stats" do
    it "returns the time stats for #{issuable_name}" do
      issuable.update!(spend_time: { duration: 1800, user_id: user.id },
                       time_estimate: 3600)

      get api("/projects/#{project.id}/#{issuable_collection_name}/#{issuable.iid}/time_stats", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['total_time_spent']).to eq(1800)
      expect(json_response['time_estimate']).to eq(3600)
    end
  end
end
