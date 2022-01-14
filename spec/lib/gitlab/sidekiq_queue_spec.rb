# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqQueue, :clean_gitlab_redis_queues do
  around do |example|
    Sidekiq::Queue.new('default').clear
    Sidekiq::Testing.disable!(&example)
    Sidekiq::Queue.new('default').clear
  end

  def add_job(args, user:, klass: 'AuthorizedProjectsWorker')
    Sidekiq::Client.push(
      'class' => klass,
      'queue' => 'default',
      'args' => args,
      'meta.user' => user.username
    )
  end

  describe '#drop_jobs!' do
    shared_examples 'queue processing' do
      let(:sidekiq_queue) { described_class.new('default') }
      let_it_be(:sidekiq_queue_user) { create(:user) }

      before do
        add_job([1], user: create(:user))
        add_job([2], user: sidekiq_queue_user, klass: 'MergeWorker')
        add_job([3], user: sidekiq_queue_user)
      end

      context 'when the queue is not processed in time' do
        before do
          allow(sidekiq_queue).to receive(:monotonic_time).and_return(1, 2, 12)
        end

        it 'returns a non-completion flag, the number of jobs deleted, and the remaining queue size' do
          expect(sidekiq_queue.drop_jobs!(search_metadata, timeout: 10))
            .to eq(completed: false,
                   deleted_jobs: timeout_deleted,
                   queue_size: 3 - timeout_deleted)
        end
      end

      context 'when the queue is processed in time' do
        it 'returns a completion flag, the number of jobs deleted, and the remaining queue size' do
          expect(sidekiq_queue.drop_jobs!(search_metadata, timeout: 10))
            .to eq(completed: true,
                   deleted_jobs: no_timeout_deleted,
                   queue_size: 3 - no_timeout_deleted)
        end
      end
    end

    context 'when there are no matching jobs' do
      include_examples 'queue processing' do
        let(:search_metadata) { { project: 1 } }
        let(:timeout_deleted) { 0 }
        let(:no_timeout_deleted) { 0 }
      end
    end

    context 'when there are matching jobs' do
      include_examples 'queue processing' do
        let(:search_metadata) { { user: sidekiq_queue_user.username } }
        let(:timeout_deleted) { 1 }
        let(:no_timeout_deleted) { 2 }
      end
    end

    context 'when there are jobs matching the class name' do
      include_examples 'queue processing' do
        let(:search_metadata) { { user: sidekiq_queue_user.username, worker_class: 'AuthorizedProjectsWorker' } }
        let(:timeout_deleted) { 1 }
        let(:no_timeout_deleted) { 1 }
      end
    end

    context 'when there are no valid metadata keys passed' do
      it 'raises NoMetadataError' do
        add_job([1], user: create(:user))

        expect { described_class.new('default').drop_jobs!({ username: 'sidekiq_queue_user' }, timeout: 1) }
          .to raise_error(described_class::NoMetadataError)
      end
    end

    context 'when the queue does not exist' do
      it 'raises InvalidQueueError' do
        expect { described_class.new('foo').drop_jobs!({ user: 'sidekiq_queue_user' }, timeout: 1) }
          .to raise_error(described_class::InvalidQueueError)
      end
    end
  end
end
