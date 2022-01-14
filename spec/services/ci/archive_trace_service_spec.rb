# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ArchiveTraceService, '#execute' do
  subject { described_class.new.execute(job, worker_name: Ci::ArchiveTraceWorker.name) }

  context 'when job is finished' do
    let(:job) { create(:ci_build, :success, :trace_live) }

    it 'creates an archived trace' do
      expect { subject }.not_to raise_error

      expect(job.reload.job_artifacts_trace).to be_exist
      expect(job.trace_metadata.trace_artifact).to eq(job.job_artifacts_trace)
    end

    context 'when trace is already archived' do
      let!(:job) { create(:ci_build, :success, :trace_artifact) }

      it 'ignores an exception' do
        expect { subject }.not_to raise_error
      end

      it 'does not create an archived trace' do
        expect { subject }.not_to change { Ci::JobArtifact.trace.count }
      end

      context 'when live trace chunks still exist' do
        before do
          create(:ci_build_trace_chunk, build: job, chunk_index: 0)
        end

        it 'removes the trace chunks' do
          expect { subject }.to change { job.trace_chunks.count }.to(0)
        end

        context 'when associated data does not exist' do
          before do
            job.job_artifacts_trace.file.remove!
          end

          it 'removes the trace artifact and builds a new one' do
            existing_trace = job.job_artifacts_trace
            expect(existing_trace).to receive(:destroy!).and_call_original

            subject

            expect(job.reload.job_artifacts_trace).to be_present
            expect(job.reload.job_artifacts_trace.file.file).to be_present
          end
        end
      end
    end

    context 'when job does not have trace' do
      let(:job) { create(:ci_build, :success) }

      it 'leaves a warning message in sidekiq log' do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: Ci::ArchiveTraceWorker.name,
          message: 'The job does not have live trace but going to be archived.',
          job_id: job.id)

        subject
      end
    end

    context 'when the job is out of archival attempts' do
      before do
        create(:ci_build_trace_metadata,
          build: job,
          archival_attempts: Ci::BuildTraceMetadata::MAX_ATTEMPTS + 1,
          last_archival_attempt_at: 1.week.ago)
      end

      it 'skips archiving' do
        expect(job.trace).not_to receive(:archive!)

        subject
      end

      it 'leaves a warning message in sidekiq log' do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: Ci::ArchiveTraceWorker.name,
          message: 'The job is out of archival attempts.',
          job_id: job.id)

        subject
      end

      context 'job has archive and chunks' do
        let(:job) { create(:ci_build, :success, :trace_artifact) }

        before do
          create(:ci_build_trace_chunk, build: job, chunk_index: 0)
        end

        context 'archive is not completed' do
          before do
            job.job_artifacts_trace.file.remove!
          end

          it 'cleanups any stale archive data' do
            expect(job.job_artifacts_trace).to be_present

            subject

            expect(job.reload.job_artifacts_trace).to be_nil
          end
        end

        it 'removes trace chunks' do
          expect { subject }.to change { job.trace_chunks.count }.to(0)
        end
      end
    end

    context 'when the archival process is backed off' do
      before do
        create(:ci_build_trace_metadata,
          build: job,
          archival_attempts: Ci::BuildTraceMetadata::MAX_ATTEMPTS - 1,
          last_archival_attempt_at: 1.hour.ago)
      end

      it 'skips archiving' do
        expect(job.trace).not_to receive(:archive!)

        subject
      end

      it 'leaves a warning message in sidekiq log' do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: Ci::ArchiveTraceWorker.name,
          message: 'The job can not be archived right now.',
          job_id: job.id)

        subject
      end
    end

    context 'when job failed to archive trace but did not raise an exception' do
      before do
        allow_next_instance_of(Gitlab::Ci::Trace) do |instance|
          allow(instance).to receive(:archive!) {}
        end
      end

      it 'leaves a warning message in sidekiq log' do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: Ci::ArchiveTraceWorker.name,
          message: 'The job does not have archived trace after archiving.',
          job_id: job.id)

        subject
      end
    end
  end

  context 'when job is running' do
    let(:job) { create(:ci_build, :running, :trace_live) }

    it 'increments Prometheus counter, sends crash report to Sentry and ignore an error for continuing to archive' do
      expect(Gitlab::ErrorTracking)
        .to receive(:track_and_raise_for_dev_exception)
        .with(::Gitlab::Ci::Trace::ArchiveError,
              issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/51502',
              job_id: job.id).once

      expect(Sidekiq.logger).to receive(:warn).with(
        class: Ci::ArchiveTraceWorker.name,
        message: "Failed to archive trace. message: Job is not finished yet.",
        job_id: job.id).and_call_original

      expect(Gitlab::Metrics)
        .to receive(:counter)
        .with(:job_trace_archive_failed_total, "Counter of failed attempts of trace archiving")
        .and_call_original

      expect { subject }.not_to raise_error
      expect(job.trace_metadata.archival_attempts).to eq(1)
    end
  end
end
