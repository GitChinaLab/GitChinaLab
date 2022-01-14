# frozen_string_literal: true

require 'rspec-parameterized'

require_relative '../../sidekiq_cluster/sidekiq_cluster'

RSpec.describe Gitlab::SidekiqCluster do # rubocop:disable RSpec/FilePath
  describe '.start' do
    it 'starts Sidekiq with the given queues, environment and options' do
      process_options = {
        pgroup: true,
        err: $stderr,
        out: $stdout
      }

      expect(Bundler).to receive(:with_original_env).and_call_original.twice

      expect(Process).to receive(:spawn).ordered.with({
          "ENABLE_SIDEKIQ_CLUSTER" => "1",
          "SIDEKIQ_WORKER_ID" => "0"
        },
        "bundle", "exec", "sidekiq", "-c10", "-eproduction", "-t25", "-gqueues:foo", "-rfoo/bar", "-qfoo,1", process_options
      )
      expect(Process).to receive(:spawn).ordered.with({
        "ENABLE_SIDEKIQ_CLUSTER" => "1",
        "SIDEKIQ_WORKER_ID" => "1"
        },
        "bundle", "exec", "sidekiq", "-c10", "-eproduction", "-t25", "-gqueues:bar,baz", "-rfoo/bar", "-qbar,1", "-qbaz,1", process_options
      )

      described_class.start([%w(foo), %w(bar baz)], env: :production, directory: 'foo/bar', max_concurrency: 20, min_concurrency: 10)
    end

    it 'starts Sidekiq with the given queues and sensible default options' do
      expected_options = {
        env: :development,
        directory: an_instance_of(String),
        max_concurrency: 50,
        min_concurrency: 0,
        worker_id: an_instance_of(Integer),
        timeout: 25,
        dryrun: false
      }

      expect(described_class).to receive(:start_sidekiq).ordered.with(%w(foo bar baz), expected_options)
      expect(described_class).to receive(:start_sidekiq).ordered.with(%w(solo), expected_options)

      described_class.start([%w(foo bar baz), %w(solo)])
    end
  end

  describe '.start_sidekiq' do
    let(:first_worker_id) { 0 }
    let(:options) do
      { env: :production, directory: 'foo/bar', max_concurrency: 20, min_concurrency: 0, worker_id: first_worker_id, timeout: 10, dryrun: false }
    end

    let(:env) { { "ENABLE_SIDEKIQ_CLUSTER" => "1", "SIDEKIQ_WORKER_ID" => first_worker_id.to_s } }
    let(:args) { ['bundle', 'exec', 'sidekiq', anything, '-eproduction', '-t10', *([anything] * 5)] }

    it 'starts a Sidekiq process' do
      allow(Process).to receive(:spawn).and_return(1)

      expect(Gitlab::ProcessManagement).to receive(:wait_async).with(1)
      expect(described_class.start_sidekiq(%w(foo), **options)).to eq(1)
    end

    it 'handles duplicate queue names' do
      allow(Process)
        .to receive(:spawn)
        .with(env, *args, anything)
        .and_return(1)

      expect(Gitlab::ProcessManagement).to receive(:wait_async).with(1)
      expect(described_class.start_sidekiq(%w(foo foo bar baz), **options)).to eq(1)
    end

    it 'runs the sidekiq process in a new process group' do
      expect(Process)
        .to receive(:spawn)
        .with(anything, *args, a_hash_including(pgroup: true))
        .and_return(1)

      allow(Gitlab::ProcessManagement).to receive(:wait_async)
      expect(described_class.start_sidekiq(%w(foo bar baz), **options)).to eq(1)
    end
  end

  describe '.count_by_queue' do
    it 'tallies the queue counts' do
      queues = [%w(foo), %w(bar baz), %w(foo)]

      expect(described_class.count_by_queue(queues)).to eq(%w(foo) => 2, %w(bar baz) => 1)
    end
  end

  describe '.concurrency' do
    using RSpec::Parameterized::TableSyntax

    where(:queue_count, :min, :max, :expected) do
      2 | 0 | 0 | 3 # No min or max specified
      2 | 0 | 9 | 3 # No min specified, value < max
      2 | 1 | 4 | 3 # Value between min and max
      2 | 4 | 5 | 4 # Value below range
      5 | 2 | 3 | 3 # Value above range
      2 | 1 | 1 | 1 # Value above explicit setting (min == max)
      0 | 3 | 3 | 3 # Value below explicit setting (min == max)
      1 | 4 | 3 | 3 # Min greater than max
    end

    with_them do
      let(:queues) { Array.new(queue_count) }

      it { expect(described_class.concurrency(queues, min, max)).to eq(expected) }
    end
  end
end
