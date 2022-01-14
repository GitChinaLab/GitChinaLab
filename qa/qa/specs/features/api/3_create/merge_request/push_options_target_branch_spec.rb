# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request push options' do
      # If run locally on GDK, push options need to be enabled on the host with the following command:
      #
      # git config --global receive.advertisepushoptions true

      let(:title) { "MR push options test #{SecureRandom.hex(8)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'merge-request-push-options'
          project.initialize_with_readme = true
        end
      end

      it 'sets a target branch', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347726' do
        target_branch = "push-options-test-target-#{SecureRandom.hex(8)}"

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = target_branch
          push.file_content = "Target branch test target branch #{SecureRandom.hex(8)}"
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = "push-options-test-#{SecureRandom.hex(8)}"
          push.file_content = "Target branch test source branch #{SecureRandom.hex(8)}"
          push.merge_request_push_options = {
            create: true,
            title: title,
            target: target_branch
          }
        end

        merge_request = project.merge_request_with_title(title)

        expect(merge_request).not_to be_nil, "There was a problem creating the merge request"
        expect(merge_request[:target_branch]).to eq(target_branch)

        merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = project
          mr.iid = merge_request[:iid]
        end.merge_via_api!

        expect(merge_request[:state]).to eq('merged')
      end
    end
  end
end
