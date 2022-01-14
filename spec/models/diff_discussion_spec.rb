# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffDiscussion do
  include RepoHelpers

  subject { described_class.new([diff_note]) }

  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project) }

  describe '#reply_attributes' do
    it 'includes position and original_position' do
      attributes = subject.reply_attributes
      expect(attributes[:position]).to eq(diff_note.position.to_json)
      expect(attributes[:original_position]).to eq(diff_note.original_position.to_json)
    end
  end

  describe '#merge_request_version_params' do
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project, importing: true) }
    let!(:merge_request_diff1) { merge_request.merge_request_diffs.create!(head_commit_sha: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9') }
    let!(:merge_request_diff2) { merge_request.merge_request_diffs.create!(head_commit_sha: nil) }
    let!(:merge_request_diff3) { merge_request.merge_request_diffs.create!(head_commit_sha: '5937ac0a7beb003549fc5fd26fc247adbce4a52e') }

    context 'when the discussion is active' do
      it 'returns an empty hash, which will end up showing the latest version' do
        expect(subject.merge_request_version_params).to eq({})
      end
    end

    context 'when the discussion is on an older merge request version' do
      let(:position) do
        Gitlab::Diff::Position.new(
          old_path: ".gitmodules",
          new_path: ".gitmodules",
          old_line: nil,
          new_line: 4,
          diff_refs: merge_request_diff1.diff_refs
        )
      end

      let(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, position: position) }

      before do
        diff_note.position = diff_note.original_position
        diff_note.save!
      end

      context 'when commit_id is not present' do
        it 'returns the diff ID for the version to show' do
          expect(subject.merge_request_version_params).to eq(diff_id: merge_request_diff1.id)
        end
      end

      context 'when commit_id is present' do
        before do
          diff_note.update_attribute(:commit_id, 'commit_123')
        end

        it 'includes the commit_id in the result' do
          expect(subject.merge_request_version_params).to eq(diff_id: merge_request_diff1.id, commit_id: 'commit_123')
        end
      end
    end

    context 'when the discussion is on a comparison between merge request versions' do
      let(:position) do
        Gitlab::Diff::Position.new(
          old_path: ".gitmodules",
          new_path: ".gitmodules",
          old_line: 4,
          new_line: 4,
          diff_refs: merge_request_diff3.compare_with(merge_request_diff1.head_commit_sha).diff_refs
        )
      end

      let(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, position: position) }

      before do
        diff_note.position = diff_note.original_position
        diff_note.save!
      end

      context 'when commit_id is not present' do
        it 'returns the diff ID and start sha of the versions to compare' do
          expect(subject.merge_request_version_params).to eq(diff_id: merge_request_diff3.id, start_sha: merge_request_diff1.head_commit_sha)
        end
      end

      context 'when commit_id is present' do
        before do
          diff_note.update_attribute(:commit_id, 'commit_123')
        end

        it 'includes the commit_id in the result' do
          expect(subject.merge_request_version_params).to eq(diff_id: merge_request_diff3.id, start_sha: merge_request_diff1.head_commit_sha, commit_id: 'commit_123')
        end
      end
    end

    context 'when the discussion does not have a merge request version' do
      let(:diff_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, diff_refs: project.commit(sample_commit.id).diff_refs) }

      before do
        diff_note.position = diff_note.original_position
        diff_note.save!
      end

      context 'when commit_id is not present' do
        it 'returns empty hash' do
          expect(subject.merge_request_version_params).to eq(nil)
        end
      end

      context 'when commit_id is present' do
        before do
          diff_note.update_attribute(:commit_id, 'commit_123')
        end

        it 'returns the commit_id' do
          expect(subject.merge_request_version_params).to eq(commit_id: 'commit_123')
        end
      end
    end
  end

  describe '#cache_key' do
    let(:notes_sha) { Digest::SHA1.hexdigest("#{diff_note.post_processed_cache_key}") }
    let(:position_sha) { Digest::SHA1.hexdigest(diff_note.position.to_json) }

    it 'returns the cache key with the position sha' do
      expect(subject.cache_key).to eq("#{described_class::CACHE_VERSION}:#{subject.id}:#{notes_sha}::#{position_sha}:")
    end

    context 'when first note of discussion has diff_note_position' do
      let!(:diff_note_position) { create(:diff_note_position, note: diff_note) }
      let(:positions_sha) { Digest::SHA1.hexdigest(diff_note_position.position.to_json) }

      it 'includes sha of diff_note_positions position' do
        expect(subject.cache_key).to eq("#{described_class::CACHE_VERSION}:#{subject.id}:#{notes_sha}::#{position_sha}:#{positions_sha}")
      end
    end
  end
end
