# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::InstrumentationHelper do
  using RSpec::Parameterized::TableSyntax

  describe '.add_instrumentation_data', :request_store do
    let(:payload) { {} }

    subject { described_class.add_instrumentation_data(payload) }

    before do
      described_class.init_instrumentation_data
    end

    it 'includes DB counts' do
      subject

      expect(payload).to include(db_count: 0, db_cached_count: 0, db_write_count: 0)
    end

    context 'when Gitaly calls are made' do
      it 'adds Gitaly data and omits Redis data' do
        project = create(:project)
        RequestStore.clear!
        project.repository.exists?

        subject

        expect(payload[:gitaly_calls]).to eq(1)
        expect(payload[:gitaly_duration_s]).to be >= 0
        expect(payload[:redis_calls]).to be_nil
        expect(payload[:redis_duration_ms]).to be_nil
      end
    end

    context 'when Redis calls are made' do
      it 'adds Redis data and omits Gitaly data' do
        Gitlab::Redis::Cache.with { |redis| redis.set('test-cache', 123) }
        Gitlab::Redis::Queues.with { |redis| redis.set('test-queues', 321) }

        subject

        # Aggregated payload
        expect(payload[:redis_calls]).to eq(2)
        expect(payload[:redis_duration_s]).to be >= 0
        expect(payload[:redis_read_bytes]).to be >= 0
        expect(payload[:redis_write_bytes]).to be >= 0

        # Shared state payload
        expect(payload[:redis_queues_calls]).to eq(1)
        expect(payload[:redis_queues_duration_s]).to be >= 0
        expect(payload[:redis_queues_read_bytes]).to be >= 0
        expect(payload[:redis_queues_write_bytes]).to be >= 0

        # Cache payload
        expect(payload[:redis_cache_calls]).to eq(1)
        expect(payload[:redis_cache_duration_s]).to be >= 0
        expect(payload[:redis_cache_read_bytes]).to be >= 0
        expect(payload[:redis_cache_write_bytes]).to be >= 0

        # Gitaly
        expect(payload[:gitaly_calls]).to be_nil
        expect(payload[:gitaly_duration]).to be_nil
      end
    end

    context 'when the request matched a Rack::Attack safelist' do
      it 'logs the safelist name' do
        Gitlab::Instrumentation::Throttle.safelist = 'foobar'

        subject

        expect(payload[:throttle_safelist]).to eq('foobar')
      end
    end

    it 'logs cpu_s duration' do
      subject

      expect(payload).to include(:cpu_s)
    end

    it 'logs the process ID' do
      subject

      expect(payload).to include(:pid)
    end

    context 'when logging memory allocations' do
      include MemoryInstrumentationHelper

      before do
        skip_memory_instrumentation!
      end

      it 'logs memory usage metrics' do
        subject

        expect(payload).to include(
          :mem_objects,
          :mem_bytes,
          :mem_mallocs
        )
      end
    end

    it 'includes DB counts' do
      subject

      expect(payload).to include(db_replica_count: 0,
                                  db_replica_cached_count: 0,
                                  db_primary_count: 0,
                                  db_primary_cached_count: 0,
                                  db_primary_wal_count: 0,
                                  db_replica_wal_count: 0,
                                  db_primary_wal_cached_count: 0,
                                  db_replica_wal_cached_count: 0)
    end

    context 'when replica caught up search was made' do
      before do
        Gitlab::SafeRequestStore[:caught_up_replica_pick_ok] = 2
        Gitlab::SafeRequestStore[:caught_up_replica_pick_fail] = 1
      end

      it 'includes related metrics' do
        subject

        expect(payload).to include(caught_up_replica_pick_ok: 2)
        expect(payload).to include(caught_up_replica_pick_fail: 1)
      end
    end

    context 'when only a single counter was updated' do
      before do
        Gitlab::SafeRequestStore[:caught_up_replica_pick_ok] = 1
        Gitlab::SafeRequestStore[:caught_up_replica_pick_fail] = nil
      end

      it 'includes only that counter into logging' do
        subject

        expect(payload).to include(caught_up_replica_pick_ok: 1)
        expect(payload).not_to include(:caught_up_replica_pick_fail)
      end
    end

    context 'when there is an uploaded file' do
      it 'adds upload data' do
        uploaded_file = UploadedFile.from_params({
          'name' => 'dir/foo.txt',
          'sha256' => 'sha256',
          'remote_url' => 'http://localhost/file',
          'remote_id' => '1234567890',
          'etag' => 'etag1234567890',
          'upload_duration' => '5.05',
          'size' => '123456'
        }, nil)

        subject

        expect(payload[:uploaded_file_upload_duration_s]).to eq(uploaded_file.upload_duration)
        expect(payload[:uploaded_file_size_bytes]).to eq(uploaded_file.size)
      end
    end
  end

  describe 'duration calculations' do
    where(:end_time, :start_time, :time_now, :expected_duration) do
      "2019-06-01T00:00:00.000+0000" | nil                            | "2019-06-01T02:00:00.000+0000" | 2.hours.to_f
      "2019-06-01T02:00:00.000+0000" | nil                            | "2019-06-01T02:00:00.001+0000" | 0.001
      "2019-06-01T02:00:00.000+0000" | "2019-05-01T02:00:00.000+0000" | "2019-06-01T02:00:01.000+0000" | 1
      nil                            | "2019-06-01T02:00:00.000+0000" | "2019-06-01T02:00:00.001+0000" | 0.001
      nil                            | nil                            | "2019-06-01T02:00:00.001+0000" | nil
      "2019-06-01T02:00:00.000+0200" | nil                            | "2019-06-01T02:00:00.000-0200" | 4.hours.to_f
      1571825569.998168              | nil                            | "2019-10-23T12:13:16.000+0200" | 26.001832
      1571825569                     | nil                            | "2019-10-23T12:13:16.000+0200" | 27
      "invalid_date"                 | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      ""                             | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      0                              | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      -1                             | nil                            | "2019-10-23T12:13:16.000+0200" | nil
      "2019-06-01T02:00:00.000+0000" | nil                            | "2019-06-01T00:00:00.000+0000" | 0
      Time.at(1571999233).utc        | nil                            | "2019-10-25T12:29:16.000+0200" | 123
    end

    describe '.queue_duration_for_job' do
      with_them do
        let(:job) { { 'enqueued_at' => end_time, 'created_at' => start_time } }

        it "returns the correct duration" do
          travel_to(Time.iso8601(time_now)) do
            expect(described_class.queue_duration_for_job(job)).to eq(expected_duration)
          end
        end
      end
    end

    describe '.enqueue_latency_for_scheduled_job' do
      with_them do
        let(:job) { { 'enqueued_at' => end_time, 'scheduled_at' => start_time } }

        it "returns the correct duration" do
          travel_to(Time.iso8601(time_now)) do
            expect(described_class.enqueue_latency_for_scheduled_job(job)).to eq(expected_duration)
          end
        end
      end
    end
  end
end
