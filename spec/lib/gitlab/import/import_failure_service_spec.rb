# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::ImportFailureService, :aggregate_failures do
  let_it_be(:import_type) { 'import_type' }
  let_it_be(:project) { create(:project, :import_started, import_type: import_type) }

  let(:exception) { StandardError.new('some error') }
  let(:import_state) { nil }
  let(:fail_import) { false }
  let(:metrics) { false }

  let(:arguments) do
    {
      project_id: project.id,
      error_source: 'SomeImporter',
      exception: exception,
      fail_import: fail_import,
      metrics: metrics,
      import_state: import_state
    }
  end

  describe '.track' do
    let(:instance) { double(:failure_service) }

    context 'with all arguments provided' do
      let(:arguments) do
        {
          exception: exception,
          import_state: '_import_state_',
          project_id: '_project_id_',
          error_source: '_error_source_',
          fail_import: '_fail_import_',
          metrics: '_metrics_'
        }
      end

      it 'invokes a new instance and executes' do
        expect(described_class).to receive(:new).with(**arguments).and_return(instance)
        expect(instance).to receive(:execute)

        described_class.track(**arguments)
      end
    end

    context 'with only necessary arguments utilizing defaults' do
      it 'invokes a new instance and executes' do
        expect(described_class).to receive(:new).with(a_hash_including(exception: exception)).and_return(instance)
        expect(instance).to receive(:execute)

        described_class.track(exception: exception)
      end
    end
  end

  describe '#execute' do
    subject(:service) { described_class.new(**arguments) }

    shared_examples 'logs the exception and fails the import' do
      it 'when the failure does not abort the import' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(
            exception,
            project_id: project.id,
            import_type: import_type,
            source: 'SomeImporter'
          )

        expect(Gitlab::Import::Logger)
          .to receive(:error)
          .with(
            message: 'importer failed',
            'error.message': 'some error',
            project_id: project.id,
            import_type: import_type,
            source: 'SomeImporter'
          )

        service.execute

        expect(project.import_state.reload.status).to eq('failed')

        expect(project.import_failures).not_to be_empty
        expect(project.import_failures.last.exception_class).to eq('StandardError')
        expect(project.import_failures.last.exception_message).to eq('some error')
        expect(project.import_failures.last.retry_count).to eq(0)
      end
    end

    shared_examples 'logs the exception and does not fail the import' do
      it 'when the failure does not abort the import' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(
            exception,
            project_id: project.id,
            import_type: import_type,
            source: 'SomeImporter'
          )

        expect(Gitlab::Import::Logger)
          .to receive(:error)
          .with(
            message: 'importer failed',
            'error.message': 'some error',
            project_id: project.id,
            import_type: import_type,
            source: 'SomeImporter'
          )

        service.execute

        expect(project.import_state.reload.status).to eq('started')

        expect(project.import_failures).not_to be_empty
        expect(project.import_failures.last.exception_class).to eq('StandardError')
        expect(project.import_failures.last.exception_message).to eq('some error')
        expect(project.import_failures.last.retry_count).to eq(nil)
      end
    end

    context 'when tracking metrics' do
      let(:metrics) { true }

      it 'tracks the failed import' do
        metrics_double = double(:metrics)

        expect(Gitlab::Import::Metrics)
          .to receive(:new)
          .with("#{project.import_type}_importer", project)
          .and_return(metrics_double)
        expect(metrics_double).to receive(:track_failed_import)

        service.execute
      end
    end

    context 'when using the project as reference' do
      context 'when it fails the import' do
        let(:fail_import) { true }

        it_behaves_like 'logs the exception and fails the import'
      end

      context 'when it does not fail the import' do
        it_behaves_like 'logs the exception and does not fail the import'
      end
    end

    context 'when using the import_state as reference' do
      let(:import_state) { project.import_state }

      context 'when it fails the import' do
        let(:fail_import) { true }

        it_behaves_like 'logs the exception and fails the import'
      end

      context 'when it does not fail the import' do
        it_behaves_like 'logs the exception and does not fail the import'
      end
    end
  end
end
