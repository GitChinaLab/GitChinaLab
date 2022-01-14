# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::JobCoordinator do
  let(:worker_class) { BackgroundMigrationWorker }
  let(:tracking_database) { worker_class.tracking_database }
  let(:coordinator) { described_class.new(worker_class) }

  describe '.for_tracking_database' do
    it 'returns an executor with the correct worker class and database' do
      coordinator = described_class.for_tracking_database(tracking_database)

      expect(coordinator.worker_class).to eq(worker_class)
    end

    context 'when an invalid value is given' do
      it 'raises an error' do
        expect do
          described_class.for_tracking_database('notvalid')
        end.to raise_error(ArgumentError, /tracking_database must be one of/)
      end
    end
  end

  describe '#queue' do
    it 'returns background migration worker queue' do
      expect(coordinator.queue).to eq(worker_class.sidekiq_options['queue'])
    end
  end

  describe '#with_shared_connection' do
    it 'yields to the block after properly configuring SharedModel' do
      expect(Gitlab::Database::SharedModel).to receive(:using_connection)
        .with(ActiveRecord::Base.connection).and_yield

      expect { |b| coordinator.with_shared_connection(&b) }.to yield_with_no_args
    end
  end

  describe '#steal' do
    context 'when there are enqueued jobs present' do
      let(:queue) do
        [
          double(args: ['Foo', [10, 20]], klass: worker_class.name),
          double(args: ['Bar', [20, 30]], klass: worker_class.name),
          double(args: ['Foo', [20, 30]], klass: 'MergeWorker')
        ]
      end

      before do
        allow(Sidekiq::Queue).to receive(:new)
          .with(coordinator.queue)
          .and_return(queue)
      end

      context 'when queue contains unprocessed jobs' do
        it 'steals jobs from a queue' do
          expect(queue[0]).to receive(:delete).and_return(true)

          expect(coordinator).to receive(:perform).with('Foo', [10, 20])

          coordinator.steal('Foo')
        end

        it 'sets up the shared connection while stealing jobs' do
          connection = double('connection')
          allow(coordinator).to receive(:connection).and_return(connection)

          expect(coordinator).to receive(:with_shared_connection).and_call_original

          expect(queue[0]).to receive(:delete).and_return(true)

          expect(coordinator).to receive(:perform).with('Foo', [10, 20]) do
            expect(Gitlab::Database::SharedModel.connection).to be(connection)
          end

          coordinator.steal('Foo') do
            expect(Gitlab::Database::SharedModel.connection).to be(connection)

            true # the job is only performed if the block returns true
          end
        end

        it 'does not steal job that has already been taken' do
          expect(queue[0]).to receive(:delete).and_return(false)

          expect(coordinator).not_to receive(:perform)

          coordinator.steal('Foo')
        end

        it 'does not steal jobs for a different migration' do
          expect(coordinator).not_to receive(:perform)

          expect(queue[0]).not_to receive(:delete)

          coordinator.steal('Baz')
        end

        context 'when a custom predicate is given' do
          it 'steals jobs that match the predicate' do
            expect(queue[0]).to receive(:delete).and_return(true)

            expect(coordinator).to receive(:perform).with('Foo', [10, 20])

            coordinator.steal('Foo') { |job| job.args.second.first == 10 && job.args.second.second == 20 }
          end

          it 'does not steal jobs that do not match the predicate' do
            expect(described_class).not_to receive(:perform)

            expect(queue[0]).not_to receive(:delete)

            coordinator.steal('Foo') { |(arg1, _)| arg1 == 5 }
          end
        end
      end

      context 'when one of the jobs raises an error' do
        let(:migration) { spy(:migration) }

        let(:queue) do
          [double(args: ['Foo', [10, 20]], klass: worker_class.name),
           double(args: ['Foo', [20, 30]], klass: worker_class.name)]
        end

        before do
          stub_const('Gitlab::BackgroundMigration::Foo', migration)

          allow(queue[0]).to receive(:delete).and_return(true)
          allow(queue[1]).to receive(:delete).and_return(true)
        end

        it 'enqueues the migration again and re-raises the error' do
          allow(migration).to receive(:perform).with(10, 20).and_raise(Exception, 'Migration error').once

          expect(worker_class).to receive(:perform_async).with('Foo', [10, 20]).once

          expect { coordinator.steal('Foo') }.to raise_error(Exception)
        end
      end
    end

    context 'when there are scheduled jobs present', :redis do
      it 'steals all jobs from the scheduled sets' do
        Sidekiq::Testing.disable! do
          worker_class.perform_in(10.minutes, 'Object')

          expect(Sidekiq::ScheduledSet.new).to be_one
          expect(coordinator).to receive(:perform).with('Object', any_args)

          coordinator.steal('Object')

          expect(Sidekiq::ScheduledSet.new).to be_none
        end
      end
    end

    context 'when there are enqueued and scheduled jobs present', :redis do
      it 'steals from the scheduled sets queue first' do
        Sidekiq::Testing.disable! do
          expect(coordinator).to receive(:perform).with('Object', [1]).ordered
          expect(coordinator).to receive(:perform).with('Object', [2]).ordered

          worker_class.perform_async('Object', [2])
          worker_class.perform_in(10.minutes, 'Object', [1])

          coordinator.steal('Object')
        end
      end
    end

    context 'when retry_dead_jobs is true', :redis do
      let(:retry_queue) do
        [double(args: ['Object', [3]], klass: worker_class.name, delete: true)]
      end

      let(:dead_queue) do
        [double(args: ['Object', [4]], klass: worker_class.name, delete: true)]
      end

      before do
        allow(Sidekiq::RetrySet).to receive(:new).and_return(retry_queue)
        allow(Sidekiq::DeadSet).to receive(:new).and_return(dead_queue)
      end

      it 'steals from the dead and retry queue' do
        Sidekiq::Testing.disable! do
          expect(coordinator).to receive(:perform).with('Object', [1]).ordered
          expect(coordinator).to receive(:perform).with('Object', [2]).ordered
          expect(coordinator).to receive(:perform).with('Object', [3]).ordered
          expect(coordinator).to receive(:perform).with('Object', [4]).ordered

          worker_class.perform_async('Object', [2])
          worker_class.perform_in(10.minutes, 'Object', [1])

          coordinator.steal('Object', retry_dead_jobs: true)
        end
      end
    end
  end

  describe '#perform' do
    let(:migration) { spy(:migration) }
    let(:connection) { double('connection') }

    before do
      stub_const('Gitlab::BackgroundMigration::Foo', migration)

      allow(coordinator).to receive(:connection).and_return(connection)
    end

    it 'performs a background migration with the configured shared connection' do
      expect(coordinator).to receive(:with_shared_connection).and_call_original

      expect(migration).to receive(:perform).with(10, 20).once do
        expect(Gitlab::Database::SharedModel.connection).to be(connection)
      end

      coordinator.perform('Foo', [10, 20])
    end
  end

  describe '.remaining', :redis do
    context 'when there are jobs remaining' do
      before do
        Sidekiq::Testing.disable! do
          MergeWorker.perform_async('Foo')
          MergeWorker.perform_in(10.minutes, 'Foo')

          5.times do
            worker_class.perform_async('Foo')
          end
          3.times do
            worker_class.perform_in(10.minutes, 'Foo')
          end
        end
      end

      it 'returns the enqueued jobs plus the scheduled jobs' do
        expect(coordinator.remaining).to eq(8)
      end
    end

    context 'when there are no jobs remaining' do
      it 'returns zero' do
        expect(coordinator.remaining).to be_zero
      end
    end
  end

  describe '.exists?', :redis do
    context 'when there are enqueued jobs present' do
      before do
        Sidekiq::Testing.disable! do
          MergeWorker.perform_async('Bar')
          worker_class.perform_async('Foo')
        end
      end

      it 'returns true if specific job exists' do
        expect(coordinator.exists?('Foo')).to eq(true)
      end

      it 'returns false if specific job does not exist' do
        expect(coordinator.exists?('Bar')).to eq(false)
      end
    end

    context 'when there are scheduled jobs present' do
      before do
        Sidekiq::Testing.disable! do
          MergeWorker.perform_in(10.minutes, 'Bar')
          worker_class.perform_in(10.minutes, 'Foo')
        end
      end

      it 'returns true if specific job exists' do
        expect(coordinator.exists?('Foo')).to eq(true)
      end

      it 'returns false if specific job does not exist' do
        expect(coordinator.exists?('Bar')).to eq(false)
      end
    end
  end

  describe '.dead_jobs?' do
    let(:queue) do
      [
        double(args: ['Foo', [10, 20]], klass: worker_class.name),
        double(args: ['Bar'], klass: 'MergeWorker')
      ]
    end

    context 'when there are dead jobs present' do
      before do
        allow(Sidekiq::DeadSet).to receive(:new).and_return(queue)
      end

      it 'returns true if specific job exists' do
        expect(coordinator.dead_jobs?('Foo')).to eq(true)
      end

      it 'returns false if specific job does not exist' do
        expect(coordinator.dead_jobs?('Bar')).to eq(false)
      end
    end
  end

  describe '.retrying_jobs?' do
    let(:queue) do
      [
        double(args: ['Foo', [10, 20]], klass: worker_class.name),
        double(args: ['Bar'], klass: 'MergeWorker')
      ]
    end

    context 'when there are dead jobs present' do
      before do
        allow(Sidekiq::RetrySet).to receive(:new).and_return(queue)
      end

      it 'returns true if specific job exists' do
        expect(coordinator.retrying_jobs?('Foo')).to eq(true)
      end

      it 'returns false if specific job does not exist' do
        expect(coordinator.retrying_jobs?('Bar')).to eq(false)
      end
    end
  end
end
