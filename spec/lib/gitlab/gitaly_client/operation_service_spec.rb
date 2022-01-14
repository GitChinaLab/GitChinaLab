# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::OperationService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository.raw }
  let(:client) { described_class.new(repository) }
  let(:gitaly_user) { Gitlab::Git::User.from_gitlab(user).to_gitaly }

  describe '#user_create_branch' do
    let(:branch_name) { 'new' }
    let(:start_point) { 'master' }
    let(:request) do
      Gitaly::UserCreateBranchRequest.new(
        repository: repository.gitaly_repository,
        branch_name: branch_name,
        start_point: start_point,
        user: gitaly_user
      )
    end

    let(:gitaly_commit) { build(:gitaly_commit) }
    let(:commit_id) { gitaly_commit.id }
    let(:gitaly_branch) do
      Gitaly::Branch.new(name: branch_name, target_commit: gitaly_commit)
    end

    let(:response) { Gitaly::UserCreateBranchResponse.new(branch: gitaly_branch) }
    let(:commit) { Gitlab::Git::Commit.new(repository, gitaly_commit) }

    subject { client.user_create_branch(branch_name, user, start_point) }

    it 'sends a user_create_branch message and returns a Gitlab::git::Branch' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_create_branch).with(request, kind_of(Hash))
        .and_return(response)

      expect(subject.name).to eq(branch_name)
      expect(subject.dereferenced_target).to eq(commit)
    end

    context "when pre_receive_error is present" do
      let(:response) do
        Gitaly::UserCreateBranchResponse.new(pre_receive_error: "GitLab: something failed")
      end

      it "throws a PreReceive exception" do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_create_branch).with(request, kind_of(Hash))
          .and_return(response)

        expect { subject }.to raise_error(
          Gitlab::Git::PreReceiveError, "something failed")
      end
    end
  end

  describe '#user_update_branch' do
    let(:branch_name) { 'my-branch' }
    let(:newrev) { '01e' }
    let(:oldrev) { '01d' }
    let(:request) do
      Gitaly::UserUpdateBranchRequest.new(
        repository: repository.gitaly_repository,
        branch_name: branch_name,
        newrev: newrev,
        oldrev: oldrev,
        user: gitaly_user
      )
    end

    let(:response) { Gitaly::UserUpdateBranchResponse.new }

    subject { client.user_update_branch(branch_name, user, newrev, oldrev) }

    it 'sends a user_update_branch message' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_update_branch).with(request, kind_of(Hash))
        .and_return(response)

      subject
    end

    describe '#user_merge_to_ref' do
      let(:first_parent_ref) { 'refs/heads/my-branch' }
      let(:source_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
      let(:ref) { 'refs/merge-requests/x/merge' }
      let(:message) { 'validación' }
      let(:response) { Gitaly::UserMergeToRefResponse.new(commit_id: 'new-commit-id') }

      let(:payload) do
        { source_sha: source_sha, branch: 'branch', target_ref: ref,
          message: message, first_parent_ref: first_parent_ref, allow_conflicts: true }
      end

      it 'sends a user_merge_to_ref message' do
        freeze_time do
          expect_any_instance_of(Gitaly::OperationService::Stub).to receive(:user_merge_to_ref) do |_, request, options|
            expect(options).to be_kind_of(Hash)
            expect(request.to_h).to eq(
              payload.merge({
                repository: repository.gitaly_repository.to_h,
                message: message.dup.force_encoding(Encoding::ASCII_8BIT),
                user: Gitlab::Git::User.from_gitlab(user).to_gitaly.to_h,
                timestamp: { nanos: 0, seconds: Time.current.to_i }
              })
            )
          end.and_return(response)

          client.user_merge_to_ref(user, **payload)
        end
      end
    end

    context "when pre_receive_error is present" do
      let(:response) do
        Gitaly::UserUpdateBranchResponse.new(pre_receive_error: "GitLab: something failed")
      end

      it "throws a PreReceive exception" do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_update_branch).with(request, kind_of(Hash))
          .and_return(response)

        expect { subject }.to raise_error(
          Gitlab::Git::PreReceiveError, "something failed")
      end
    end
  end

  describe '#user_delete_branch' do
    let(:branch_name) { 'my-branch' }
    let(:request) do
      Gitaly::UserDeleteBranchRequest.new(
        repository: repository.gitaly_repository,
        branch_name: branch_name,
        user: gitaly_user
      )
    end

    let(:response) { Gitaly::UserDeleteBranchResponse.new }

    subject { client.user_delete_branch(branch_name, user) }

    it 'sends a user_delete_branch message' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_delete_branch).with(request, kind_of(Hash))
        .and_return(response)

      subject
    end

    context "when pre_receive_error is present" do
      let(:response) do
        Gitaly::UserDeleteBranchResponse.new(pre_receive_error: "GitLab: something failed")
      end

      it "throws a PreReceive exception" do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_delete_branch).with(request, kind_of(Hash))
          .and_return(response)

        expect { subject }.to raise_error(
          Gitlab::Git::PreReceiveError, "something failed")
      end
    end
  end

  describe '#user_merge_branch' do
    let(:target_branch) { 'master' }
    let(:source_sha) { '5937ac0a7beb003549fc5fd26fc247adbce4a52e' }
    let(:message) { 'Merge a branch' }

    subject { client.user_merge_branch(user, source_sha, target_branch, message) {} }

    it 'sends a user_merge_branch message' do
      expect(subject).to be_a(Gitlab::Git::OperationService::BranchUpdate)
      expect(subject.newrev).to be_present
      expect(subject.repo_created).to be(false)
      expect(subject.branch_created).to be(false)
    end

    context 'with an exception with the UserMergeBranchError' do
      let(:permission_error) do
        GRPC::PermissionDenied.new(
          "GitLab: You are not allowed to push code to this project.",
          { "grpc-status-details-bin" =>
           "\b\a\x129GitLab: You are not allowed to push code to this project.\x1A\xDE\x01\n/type.googleapis.com/gitaly.UserMergeBranchError\x12\xAA\x01\n\xA7\x01\n1You are not allowed to push code to this project.\x12\x03web\x1A\auser-15\"df15b32277d2c55c6c595845a87109b09c913c556 5d6e0f935ad9240655f64e883cd98fad6f9a17ee refs/heads/master\n" }
        )
      end

      it 'raises PreRecieveError with the error message' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_merge_branch).with(kind_of(Enumerator), kind_of(Hash))
          .and_raise(permission_error)

        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Gitlab::Git::PreReceiveError)
          expect(error.message).to eq("You are not allowed to push code to this project.")
        end
      end
    end

    context 'with an exception without the detailed error' do
      let(:permission_error) do
        GRPC::PermissionDenied.new
      end

      it 'raises PermissionDenied' do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_merge_branch).with(kind_of(Enumerator), kind_of(Hash))
          .and_raise(permission_error)

        expect { subject }.to raise_error(GRPC::PermissionDenied)
      end
    end
  end

  describe '#user_ff_branch' do
    let(:target_branch) { 'my-branch' }
    let(:source_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
    let(:request) do
      Gitaly::UserFFBranchRequest.new(
        repository: repository.gitaly_repository,
        branch: target_branch,
        commit_id: source_sha,
        user: gitaly_user
      )
    end

    let(:branch_update) do
      Gitaly::OperationBranchUpdate.new(
        commit_id: source_sha,
        repo_created: false,
        branch_created: false
      )
    end

    let(:response) { Gitaly::UserFFBranchResponse.new(branch_update: branch_update) }

    before do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_ff_branch).with(request, kind_of(Hash))
        .and_return(response)
    end

    subject { client.user_ff_branch(user, source_sha, target_branch) }

    it 'sends a user_ff_branch message and returns a BranchUpdate object' do
      expect(subject).to be_a(Gitlab::Git::OperationService::BranchUpdate)
      expect(subject.newrev).to eq(source_sha)
      expect(subject.repo_created).to be(false)
      expect(subject.branch_created).to be(false)
    end

    context 'when the response has no branch_update' do
      let(:response) { Gitaly::UserFFBranchResponse.new }

      it { expect(subject).to be_nil }
    end

    context "when the pre-receive hook fails" do
      let(:response) do
        Gitaly::UserFFBranchResponse.new(
          branch_update: nil,
          pre_receive_error: "pre-receive hook error message\n"
        )
      end

      it "raises the error" do
        # the PreReceiveError class strips the GL-HOOK-ERR prefix from this error
        expect { subject }.to raise_error(Gitlab::Git::PreReceiveError, "pre-receive hook failed.")
      end
    end
  end

  shared_examples 'cherry pick and revert errors' do
    context 'when a pre_receive_error is present' do
      let(:response) { response_class.new(pre_receive_error: "GitLab: something failed") }

      it 'raises a PreReceiveError' do
        expect { subject }.to raise_error(Gitlab::Git::PreReceiveError, "something failed")
      end
    end

    context 'when a commit_error is present' do
      let(:response) { response_class.new(commit_error: "something failed") }

      it 'raises a CommitError' do
        expect { subject }.to raise_error(Gitlab::Git::CommitError, "something failed")
      end
    end

    context 'when a create_tree_error is present' do
      let(:response) { response_class.new(create_tree_error: "something failed", create_tree_error_code: 'EMPTY') }

      it 'raises a CreateTreeError' do
        expect { subject }.to raise_error(Gitlab::Git::Repository::CreateTreeError) do |error|
          expect(error.error_code).to eq(:empty)
        end
      end
    end

    context 'when branch_update is nil' do
      let(:response) { response_class.new }

      it { expect(subject).to be_nil }
    end
  end

  describe '#user_cherry_pick' do
    let(:response_class) { Gitaly::UserCherryPickResponse }

    subject do
      client.user_cherry_pick(
        user: user,
        commit: repository.commit,
        branch_name: 'master',
        message: 'Cherry-pick message',
        start_branch_name: 'master',
        start_repository: repository
      )
    end

    before do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_cherry_pick).with(kind_of(Gitaly::UserCherryPickRequest), kind_of(Hash))
        .and_return(response)
    end

    it_behaves_like 'cherry pick and revert errors'
  end

  describe '#user_revert' do
    let(:response_class) { Gitaly::UserRevertResponse }

    subject do
      client.user_revert(
        user: user,
        commit: repository.commit,
        branch_name: 'master',
        message: 'Revert message',
        start_branch_name: 'master',
        start_repository: repository
      )
    end

    before do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_revert).with(kind_of(Gitaly::UserRevertRequest), kind_of(Hash))
        .and_return(response)
    end

    it_behaves_like 'cherry pick and revert errors'
  end

  describe '#user_squash' do
    let(:start_sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
    let(:end_sha) { '54cec5282aa9f21856362fe321c800c236a61615' }
    let(:commit_message) { 'Squash message' }

    let(:time) do
      Time.now.utc
    end

    let(:request) do
      Gitaly::UserSquashRequest.new(
        repository: repository.gitaly_repository,
        user: gitaly_user,
        start_sha: start_sha,
        end_sha: end_sha,
        author: gitaly_user,
        commit_message: commit_message,
        timestamp: Google::Protobuf::Timestamp.new(seconds: time.to_i)
      )
    end

    let(:squash_sha) { 'f00' }
    let(:response) { Gitaly::UserSquashResponse.new(squash_sha: squash_sha) }

    subject do
      client.user_squash(user, start_sha, end_sha, user, commit_message, time)
    end

    it 'sends a user_squash message and returns the squash sha' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_squash).with(request, kind_of(Hash))
        .and_return(response)

      expect(subject).to eq(squash_sha)
    end

    context "when git_error is present" do
      let(:response) do
        Gitaly::UserSquashResponse.new(git_error: "something failed")
      end

      it "raises a GitError exception" do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_squash).with(request, kind_of(Hash))
          .and_return(response)

        expect { subject }.to raise_error(
          Gitlab::Git::Repository::GitError, "something failed")
      end
    end

    describe '#user_commit_files' do
      subject do
        client.user_commit_files(
          gitaly_user, 'my-branch', 'Commit files message', [], 'janedoe@example.com', 'Jane Doe',
          'master', repository)
      end

      before do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_commit_files).with(kind_of(Enumerator), kind_of(Hash))
          .and_return(response)
      end

      context 'when a pre_receive_error is present' do
        let(:response) { Gitaly::UserCommitFilesResponse.new(pre_receive_error: "GitLab: something failed") }

        it 'raises a PreReceiveError' do
          expect { subject }.to raise_error(Gitlab::Git::PreReceiveError, "something failed")
        end
      end

      context 'when an index_error is present' do
        let(:response) { Gitaly::UserCommitFilesResponse.new(index_error: "something failed") }

        it 'raises a PreReceiveError' do
          expect { subject }.to raise_error(Gitlab::Git::Index::IndexError, "something failed")
        end
      end

      context 'when branch_update is nil' do
        let(:response) { Gitaly::UserCommitFilesResponse.new }

        it { expect(subject).to be_nil }
      end
    end
  end

  describe '#user_commit_patches' do
    let(:patches_folder) { Rails.root.join('spec/fixtures/patchfiles') }
    let(:patch_content) do
      patch_names.map { |name| File.read(File.join(patches_folder, name)) }.join("\n")
    end

    let(:patch_names) { %w(0001-This-does-not-apply-to-the-feature-branch.patch) }
    let(:branch_name) { 'branch-with-patches' }

    subject(:commit_patches) do
      client.user_commit_patches(user, branch_name, patch_content)
    end

    it 'applies the patch correctly' do
      branch_update = commit_patches

      expect(branch_update).to be_branch_created

      commit = repository.commit(branch_update.newrev)
      expect(commit.author_email).to eq('patchuser@gitlab.org')
      expect(commit.committer_email).to eq(user.email)
      expect(commit.message.chomp).to eq('This does not apply to the `feature` branch')
    end

    context 'when the patch could not be applied' do
      let(:patch_names) { %w(0001-This-does-not-apply-to-the-feature-branch.patch) }
      let(:branch_name) { 'feature' }

      it 'raises the correct error' do
        expect { commit_patches }.to raise_error(GRPC::FailedPrecondition)
      end
    end
  end
end
