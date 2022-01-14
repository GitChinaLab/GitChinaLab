# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../metrics_server/metrics_server'

# End-to-end tests for the metrics server process we use to serve metrics
# from forking applications (Sidekiq, Puma) to the Prometheus scraper.
RSpec.describe 'bin/metrics-server', :aggregate_failures do
  let(:config_file) { Tempfile.new('gitlab.yml') }
  let(:config) do
    {
      'test' => {
        'monitoring' => {
          'sidekiq_exporter' => {
            'address' => 'localhost',
            'enabled' => true,
            'port' => 3807
          }
        }
      }
    }
  end

  context 'with a running server' do
    before do
      # We need to send a request to localhost
      WebMock.allow_net_connect!

      config_file.write(YAML.dump(config))
      config_file.close

      env = {
        'GITLAB_CONFIG' => config_file.path,
        'METRICS_SERVER_TARGET' => 'sidekiq',
        'WIPE_METRICS_DIR' => '1'
      }
      @pid = Process.spawn(env, 'bin/metrics-server', pgroup: true)
    end

    after do
      webmock_enable!

      if @pid
        pgrp = Process.getpgid(@pid)

        Timeout.timeout(5) do
          Process.kill('TERM', -pgrp)
          Process.waitpid(@pid)
        end

        expect(Gitlab::ProcessManagement.process_alive?(@pid)).to be(false)
      end
    rescue Errno::ESRCH => _
      # 'No such process' means the process died before
    ensure
      config_file.unlink
    end

    it 'serves /metrics endpoint' do
      expect do
        Timeout.timeout(5) do
          http_ok = false
          until http_ok
            sleep 1
            response = Gitlab::HTTP.try_get("http://localhost:3807/metrics", allow_local_requests: true)
            http_ok = response&.success?
          end
        end
      end.not_to raise_error
    end
  end
end
