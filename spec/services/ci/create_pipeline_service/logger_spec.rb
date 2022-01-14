# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  context 'pipeline logger' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.owner }

    let(:ref) { 'refs/heads/master' }
    let(:service)  { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { service.execute(:push).payload }
    let(:file_location) { 'spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml' }

    before do
      stub_ci_pipeline_yaml_file(gitlab_ci_yaml)
    end

    let(:counters) do
      {
        'count' => a_kind_of(Numeric),
        'avg'   => a_kind_of(Numeric),
        'max'   => a_kind_of(Numeric),
        'min'   => a_kind_of(Numeric)
      }
    end

    let(:loggable_data) do
      {
        'pipeline_creation_caller' => 'Ci::CreatePipelineService',
        'pipeline_source' => 'push',
        'pipeline_id' => a_kind_of(Numeric),
        'pipeline_persisted' => true,
        'project_id' => project.id,
        'pipeline_creation_service_duration_s' => a_kind_of(Numeric),
        'pipeline_creation_duration_s' => counters,
        'pipeline_size_count' => counters,
        'pipeline_step_gitlab_ci_pipeline_chain_seed_duration_s' => counters
      }
    end

    context 'when the duration is under the threshold' do
      it 'does not create a log entry but it collects the data' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)
        expect(pipeline).to be_created_successfully

        expect(service.logger.observations_hash)
          .to match(
            a_hash_including(
              'pipeline_creation_duration_s' => counters,
              'pipeline_size_count' => counters,
              'pipeline_step_gitlab_ci_pipeline_chain_seed_duration_s' => counters
            )
          )
      end
    end

    context 'when the durations exceeds the threshold' do
      let(:timer) do
        proc do
          @timer = @timer.to_i + 30
        end
      end

      before do
        allow(Gitlab::Ci::Pipeline::Logger)
          .to receive(:current_monotonic_time) { timer.call }
      end

      it 'creates a log entry' do
        expect(Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(a_hash_including(loggable_data))
          .and_call_original

        expect(pipeline).to be_created_successfully
      end

      context 'when the pipeline is not persisted' do
        let(:loggable_data) do
          {
            'pipeline_creation_caller' => 'Ci::CreatePipelineService',
            'pipeline_source' => 'push',
            'pipeline_id' => nil,
            'pipeline_persisted' => false,
            'project_id' => project.id,
            'pipeline_creation_service_duration_s' => a_kind_of(Numeric),
            'pipeline_step_gitlab_ci_pipeline_chain_seed_duration_s' => counters
          }
        end

        before do
          allow_next_instance_of(Ci::Pipeline) do |pipeline|
            expect(pipeline).to receive(:save!).and_raise { RuntimeError }
          end
        end

        it 'creates a log entry' do
          expect(Gitlab::AppJsonLogger)
            .to receive(:info)
            .with(a_hash_including(loggable_data))
            .and_call_original

          expect { pipeline }.to raise_error(RuntimeError)
        end
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(ci_pipeline_creation_logger: false)
        end

        it 'does not create a log entry' do
          expect(Gitlab::AppJsonLogger).not_to receive(:info)

          expect(pipeline).to be_created_successfully
          expect(service.logger.observations_hash).to eq({})
        end
      end
    end

    context 'when the size exceeds the threshold' do
      before do
        allow_next_instance_of(Ci::Pipeline) do |pipeline|
          allow(pipeline).to receive(:total_size) { 5000 }
        end
      end

      it 'creates a log entry' do
        expect(Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(a_hash_including(loggable_data))
          .and_call_original

        expect(pipeline).to be_created_successfully
      end
    end
  end
end
