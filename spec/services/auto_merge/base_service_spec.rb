# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMerge::BaseService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user, params) }
  let(:merge_request) { create(:merge_request) }
  let(:params) { {} }

  describe '#execute' do
    subject { service.execute(merge_request) }

    before do
      allow(AutoMergeProcessWorker).to receive(:perform_async) {}
    end

    it 'sets properies to the merge request' do
      subject

      merge_request.reload
      expect(merge_request).to be_auto_merge_enabled
      expect(merge_request.merge_user).to eq(user)
      expect(merge_request.auto_merge_strategy).to eq('base')
    end

    it 'yields block' do
      expect { |b| service.execute(merge_request, &b) }.to yield_control.once
    end

    it 'returns activated strategy name' do
      is_expected.to eq(:base)
    end

    context 'when merge parameters are given' do
      let(:params) do
        {
          'commit_message' => "Merge branch 'patch-12' into 'master'",
          'sha' => "200fcc9c260f7219eaf0daba87d818f0922c5b18",
          'should_remove_source_branch' => false,
          'squash' => false,
          'squash_commit_message' => "Update README.md"
        }
      end

      it 'sets merge parameters' do
        subject

        merge_request.reload
        expect(merge_request.merge_params['commit_message']).to eq("Merge branch 'patch-12' into 'master'")
        expect(merge_request.merge_params['sha']).to eq('200fcc9c260f7219eaf0daba87d818f0922c5b18')
        expect(merge_request.merge_params['should_remove_source_branch']).to eq(false)
        expect(merge_request.squash_on_merge?).to eq(false)
        expect(merge_request.merge_params['squash_commit_message']).to eq('Update README.md')
      end
    end

    context 'when strategy is merge when pipeline succeeds' do
      let(:service) { AutoMerge::MergeWhenPipelineSucceedsService.new(project, user) }

      before do
        pipeline = build(:ci_pipeline)
        allow(merge_request).to receive(:actual_head_pipeline) { pipeline }
      end

      it 'sets the auto merge strategy' do
        subject

        merge_request.reload
        expect(merge_request.auto_merge_strategy).to eq(AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS)
      end

      it 'returns activated strategy name' do
        is_expected.to eq(AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS.to_sym)
      end

      it 'calls AutoMergeProcessWorker' do
        expect(AutoMergeProcessWorker).to receive(:perform_async).with(merge_request.id).once

        subject
      end
    end

    context 'when failed to save merge request' do
      before do
        allow(merge_request).to receive(:save!) { raise ActiveRecord::RecordInvalid }
      end

      it 'does not yield block' do
        expect { |b| service.execute(merge_request, &b) }.not_to yield_control
      end

      it 'returns failed' do
        is_expected.to eq(:failed)
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception).with(kind_of(ActiveRecord::RecordInvalid),
                                             merge_request_id: merge_request.id)

        subject
      end
    end

    context 'when exception happens in yield block' do
      def execute_with_error_in_yield
        service.execute(merge_request) { raise 'Something went wrong' }
      end

      it 'returns failed status' do
        expect(execute_with_error_in_yield).to eq(:failed)
      end

      it 'rollback the transaction' do
        execute_with_error_in_yield

        merge_request.reload
        expect(merge_request).not_to be_auto_merge_enabled
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception).with(kind_of(RuntimeError),
                                             merge_request_id: merge_request.id)

        execute_with_error_in_yield
      end
    end
  end

  describe '#update' do
    subject { service.update(merge_request) } # rubocop:disable Rails/SaveBang

    let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }

    context 'when merge params are specified' do
      let(:params) do
        {
          'commit_message' => "Merge branch 'patch-12' into 'master'",
          'sha' => "200fcc9c260f7219eaf0daba87d818f0922c5b18",
          'should_remove_source_branch' => false,
          'squash_commit_message' => "Update README.md"
        }
      end

      it 'updates merge params' do
        expect { subject }.to change {
          merge_request.reload.merge_params.slice(*params.keys)
        }.from({}).to(params)
      end
    end
  end

  shared_examples_for 'Canceled or Dropped' do
    it 'removes properies from the merge request' do
      subject

      merge_request.reload
      expect(merge_request).not_to be_auto_merge_enabled
      expect(merge_request.merge_user).to be_nil
      expect(merge_request.auto_merge_strategy).to be_nil
    end

    it 'yields block' do
      expect { |b| service.cancel(merge_request, &b) }.to yield_control.once
    end

    it 'returns success status' do
      expect(subject[:status]).to eq(:success)
    end

    context 'when merge params are set' do
      before do
        merge_request.update!(merge_params:
          {
            'should_remove_source_branch' => false,
            'commit_message' => "Merge branch 'patch-12' into 'master'",
            'squash_commit_message' => "Update README.md",
            'auto_merge_strategy' => 'merge_when_pipeline_succeeds'
          })
      end

      it 'removes merge parameters' do
        subject

        merge_request.reload
        expect(merge_request.merge_params['should_remove_source_branch']).to be_nil
        expect(merge_request.merge_params['commit_message']).to be_nil
        expect(merge_request.merge_params['squash_commit_message']).to be_nil
        expect(merge_request.merge_params['auto_merge_strategy']).to be_nil
      end
    end

    context 'when failed to save' do
      before do
        allow(merge_request).to receive(:save!) { raise ActiveRecord::RecordInvalid }
      end

      it 'does not yield block' do
        expect { |b| service.execute(merge_request, &b) }.not_to yield_control
      end
    end
  end

  describe '#cancel' do
    subject { service.cancel(merge_request) }

    let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }

    it_behaves_like 'Canceled or Dropped'

    context 'when failed to save merge request' do
      before do
        allow(merge_request).to receive(:save!) { raise ActiveRecord::RecordInvalid }
      end

      it 'returns error status' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq("Can't cancel the automatic merge")
      end
    end

    context 'when exception happens in yield block' do
      def cancel_with_error_in_yield
        service.cancel(merge_request) { raise 'Something went wrong' }
      end

      it 'returns error' do
        result = cancel_with_error_in_yield
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Can't cancel the automatic merge")
      end

      it 'rollback the transaction' do
        cancel_with_error_in_yield

        merge_request.reload
        expect(merge_request).to be_auto_merge_enabled
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception).with(kind_of(RuntimeError),
                                             merge_request_id: merge_request.id)

        cancel_with_error_in_yield
      end
    end
  end

  describe '#abort' do
    subject { service.abort(merge_request, reason) }

    let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }
    let(:reason) { 'an error'}

    it_behaves_like 'Canceled or Dropped'

    context 'when failed to save' do
      before do
        allow(merge_request).to receive(:save!) { raise ActiveRecord::RecordInvalid }
      end

      it 'returns error status' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq("Can't abort the automatic merge")
      end
    end

    context 'when exception happens in yield block' do
      def abort_with_error_in_yield
        service.abort(merge_request, reason) { raise 'Something went wrong' }
      end

      it 'returns error' do
        result = abort_with_error_in_yield
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Can't abort the automatic merge")
      end

      it 'rollback the transaction' do
        abort_with_error_in_yield

        merge_request.reload
        expect(merge_request).to be_auto_merge_enabled
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception).with(kind_of(RuntimeError),
                                             merge_request_id: merge_request.id)

        abort_with_error_in_yield
      end
    end
  end
end
