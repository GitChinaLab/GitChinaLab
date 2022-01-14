# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ChangesAccess do
  include_context 'changes access checks context'

  subject { changes_access }

  describe '#validate!' do
    before do
      allow(project).to receive(:lfs_enabled?).and_return(true)
    end

    context 'without failed checks' do
      it "doesn't raise an error" do
        expect { subject.validate! }.not_to raise_error
      end

      it 'calls lfs checks' do
        expect_next_instance_of(Gitlab::Checks::LfsCheck) do |instance|
          expect(instance).to receive(:validate!)
        end

        subject.validate!
      end
    end

    context 'when time limit was reached' do
      it 'raises a TimeoutError' do
        logger = Gitlab::Checks::TimedLogger.new(start_time: timeout.ago, timeout: timeout)
        access = described_class.new(changes,
                                     project: project,
                                     user_access: user_access,
                                     protocol: protocol,
                                     logger: logger)

        expect { access.validate! }.to raise_error(Gitlab::Checks::TimedLogger::TimeoutError)
      end
    end
  end

  describe '#commits' do
    it 'calls #new_commits' do
      expect(project.repository).to receive(:new_commits).and_call_original

      expect(subject.commits).to eq([])
    end

    context 'when changes contain empty revisions' do
      let(:changes) { [{ newrev: newrev }, { newrev: '' }, { newrev: Gitlab::Git::BLANK_SHA }] }
      let(:expected_commit) { instance_double(Commit) }

      it 'returns only commits with non empty revisions' do
        expect(project.repository).to receive(:new_commits).with([newrev], { allow_quarantine: true }) { [expected_commit] }
        expect(subject.commits).to eq([expected_commit])
      end
    end
  end

  describe '#commits_for' do
    let(:new_commits) { [] }
    let(:expected_commits) { [] }

    shared_examples 'a listing of new commits' do
      it 'returns expected commits' do
        expect(subject).to receive(:commits).and_return(new_commits)

        expect(subject.commits_for(newrev)).to eq(expected_commits)
      end
    end

    context 'with no commits' do
      it_behaves_like 'a listing of new commits'
    end

    context 'with unrelated commits' do
      let(:new_commits) { [create_commit('1234', %w[1111 2222])] }

      it_behaves_like 'a listing of new commits'
    end

    context 'with single related commit' do
      let(:new_commits) { [create_commit(newrev, %w[1111 2222])] }
      let(:expected_commits) { new_commits }

      it_behaves_like 'a listing of new commits'
    end

    context 'with single related and unrelated commit' do
      let(:new_commits) do
        [
          create_commit(newrev, %w[1111 2222]),
          create_commit('abcd', %w[1111 2222])
        ]
      end

      let(:expected_commits) do
        [create_commit(newrev, %w[1111 2222])]
      end

      it_behaves_like 'a listing of new commits'
    end

    context 'with multiple related commits' do
      let(:new_commits) do
        [
          create_commit(newrev, %w[1111]),
          create_commit('1111', %w[2222]),
          create_commit('abcd', [])
        ]
      end

      let(:expected_commits) do
        [
          create_commit(newrev, %w[1111]),
          create_commit('1111', %w[2222])
        ]
      end

      it_behaves_like 'a listing of new commits'
    end

    context 'with merge commits' do
      let(:new_commits) do
        [
          create_commit(newrev, %w[1111 2222 3333]),
          create_commit('1111', []),
          create_commit('3333', %w[4444]),
          create_commit('4444', [])
        ]
      end

      let(:expected_commits) do
        [
          create_commit(newrev, %w[1111 2222 3333]),
          create_commit('1111', []),
          create_commit('3333', %w[4444]),
          create_commit('4444', [])
        ]
      end

      it_behaves_like 'a listing of new commits'
    end

    context 'with criss-cross merges' do
      let(:new_commits) do
        [
          create_commit(newrev, %w[a1 b1]),
          create_commit('a1', %w[a2 b2]),
          create_commit('a2', %w[a3 b3]),
          create_commit('a3', %w[c]),
          create_commit('b1', %w[b2 a2]),
          create_commit('b2', %w[b3 a3]),
          create_commit('b3', %w[c]),
          create_commit('c', [])
        ]
      end

      let(:expected_commits) do
        [
          create_commit(newrev, %w[a1 b1]),
          create_commit('a1', %w[a2 b2]),
          create_commit('b1', %w[b2 a2]),
          create_commit('a2', %w[a3 b3]),
          create_commit('b2', %w[b3 a3]),
          create_commit('a3', %w[c]),
          create_commit('b3', %w[c]),
          create_commit('c', [])
        ]
      end

      it_behaves_like 'a listing of new commits'
    end
  end

  describe '#single_change_accesses' do
    let(:commits_for) { {} }
    let(:expected_accesses) { [] }

    shared_examples '#single_change_access' do
      before do
        commits_for.each do |id, commits|
          expect(subject)
            .to receive(:commits_for)
            .with(id)
            .and_return(commits)
        end
      end

      it 'returns an array of SingleChangeAccess' do
        # Commits are wrapped in a Gitlab::Lazy and thus need to be resolved
        # first such that we can directly compare types.
        actual_accesses = subject.single_change_accesses
          .each { |access| access.instance_variable_set(:@commits, access.commits.to_a) }

        expect(actual_accesses).to match_array(expected_accesses)
      end
    end

    context 'with no changes' do
      let(:changes) { [] }

      it_behaves_like '#single_change_access'
    end

    context 'with a single change and no new commits' do
      let(:commits_for) { { 'new' => [] } }
      let(:changes) do
        [
          { oldrev: 'old', newrev: 'new', ref: 'refs/heads/branch' }
        ]
      end

      let(:expected_accesses) do
        [
          have_attributes(oldrev: 'old', newrev: 'new', ref: 'refs/heads/branch', commits: [])
        ]
      end

      it_behaves_like '#single_change_access'
    end

    context 'with a single change and new commits' do
      let(:commits_for) { { 'new' => [create_commit('new', [])] } }
      let(:changes) do
        [
          { oldrev: 'old', newrev: 'new', ref: 'refs/heads/branch' }
        ]
      end

      let(:expected_accesses) do
        [
          have_attributes(oldrev: 'old', newrev: 'new', ref: 'refs/heads/branch', commits: [create_commit('new', [])])
        ]
      end

      it_behaves_like '#single_change_access'
    end

    context 'with multiple changes' do
      let(:commits_for) do
        {
          'a' => [create_commit('a', [])],
          'c' => [create_commit('c', [])],
          'd' => []
        }
      end

      let(:changes) do
        [
          { newrev: 'a', ref: 'refs/heads/a' },
          { oldrev: 'b', ref: 'refs/heads/b' },
          { oldrev: 'a', newrev: 'c', ref: 'refs/heads/c' },
          { newrev: 'd', ref: 'refs/heads/d' }
        ]
      end

      let(:expected_accesses) do
        [
          have_attributes(newrev: 'a', ref: 'refs/heads/a', commits: [create_commit('a', [])]),
          have_attributes(oldrev: 'b', ref: 'refs/heads/b', commits: []),
          have_attributes(oldrev: 'a', newrev: 'c', ref: 'refs/heads/c', commits: [create_commit('c', [])]),
          have_attributes(newrev: 'd', ref: 'refs/heads/d', commits: [])
        ]
      end

      it_behaves_like '#single_change_access'
    end
  end

  def create_commit(id, parent_ids)
    Gitlab::Git::Commit.new(project.repository, {
      id: id,
      parent_ids: parent_ids
    })
  end
end
