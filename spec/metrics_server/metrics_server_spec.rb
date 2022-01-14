# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../metrics_server/metrics_server'
require_relative '../support/helpers/next_instance_of'

RSpec.describe MetricsServer do # rubocop:disable RSpec/FilePath
  include NextInstanceOf

  before do
    # We do not want this to have knock-on effects on the test process.
    allow(Gitlab::ProcessManagement).to receive(:modify_signals)
  end

  describe '.spawn' do
    context 'when in parent process' do
      it 'forks into a new process and detaches it' do
        expect(Process).to receive(:fork).and_return(99)
        expect(Process).to receive(:detach).with(99)

        described_class.spawn('sidekiq', metrics_dir: 'path/to/metrics')
      end
    end

    context 'when in child process' do
      before do
        # This signals the process that it's "inside" the fork
        expect(Process).to receive(:fork).and_return(nil)
        expect(Process).not_to receive(:detach)
      end

      it 'starts the metrics server with the given arguments' do
        expect_next_instance_of(MetricsServer) do |server|
          expect(server).to receive(:start)
        end

        described_class.spawn('sidekiq', metrics_dir: 'path/to/metrics')
      end

      it 'resets signal handlers from parent process' do
        expect(Gitlab::ProcessManagement).to receive(:modify_signals).with(%i[A B], 'DEFAULT')

        described_class.spawn('sidekiq', metrics_dir: 'path/to/metrics', trapped_signals: %i[A B])
      end
    end
  end

  describe '#start' do
    let(:exporter_class) { Class.new(Gitlab::Metrics::Exporter::BaseExporter) }
    let(:exporter_double) { double('fake_exporter', start: true) }
    let(:prometheus_config) { ::Prometheus::Client.configuration }
    let(:metrics_dir) { Dir.mktmpdir }
    let(:settings) { { "fake_exporter" => { "enabled" => true } } }
    let!(:old_metrics_dir) { prometheus_config.multiprocess_files_dir }

    subject(:metrics_server) { described_class.new('fake', metrics_dir, true)}

    before do
      stub_const('Gitlab::Metrics::Exporter::FakeExporter', exporter_class)
      expect(exporter_class).to receive(:instance).with(settings['fake_exporter'], synchronous: true).and_return(exporter_double)
      expect(Settings).to receive(:monitoring).and_return(settings)
    end

    after do
      Gitlab::Metrics.reset_registry!
      FileUtils.rm_rf(metrics_dir, secure: true)
      prometheus_config.multiprocess_files_dir = old_metrics_dir
    end

    it 'configures ::Prometheus::Client' do
      metrics_server.start

      expect(prometheus_config.multiprocess_files_dir).to eq metrics_dir
    end

    it 'ensures that metrics directory exists in correct mode (0700)' do
      expect(FileUtils).to receive(:mkdir_p).with(metrics_dir, mode: 0700)

      metrics_server.start
    end

    context 'when wipe_metrics_dir is true' do
      subject(:metrics_server) { described_class.new('fake', metrics_dir, true)}

      it 'removes any old metrics files' do
        FileUtils.touch("#{metrics_dir}/remove_this.db")

        expect { metrics_server.start }.to change { Dir.empty?(metrics_dir) }.from(false).to(true)
      end
    end

    context 'when wipe_metrics_dir is false' do
      subject(:metrics_server) { described_class.new('fake', metrics_dir, false)}

      it 'does not remove any old metrics files' do
        FileUtils.touch("#{metrics_dir}/remove_this.db")

        expect { metrics_server.start }.not_to change { Dir.empty?(metrics_dir) }.from(false)
      end
    end

    it 'starts a metrics server' do
      expect(exporter_double).to receive(:start)

      metrics_server.start
    end
  end
end
