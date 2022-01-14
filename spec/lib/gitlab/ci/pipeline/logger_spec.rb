# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Logger do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline, project: project) }

  subject(:logger) { described_class.new(project: project) }

  describe '#log_when' do
    it 'stores blocks for later evaluation' do
      logger.log_when { |obs| true }

      expect(logger.send(:log_conditions).first).to be_a(Proc)
    end
  end

  describe '#instrument' do
    it "returns the block's value" do
      expect(logger.instrument(:expensive_operation) { 123 }).to eq(123)
    end

    it 'records durations of instrumented operations' do
      loggable_data = {
        'expensive_operation_duration_s' => {
          'count' => 1,
          'avg' => a_kind_of(Numeric),
          'max' => a_kind_of(Numeric),
          'min' => a_kind_of(Numeric)
        }
      }

      logger.instrument(:expensive_operation) { 123 }
      expect(logger.observations_hash).to match(a_hash_including(loggable_data))
    end

    it 'raises an error when block is not provided' do
      expect { logger.instrument(:expensive_operation) }
        .to raise_error(ArgumentError, 'block not given')
    end
  end

  describe '#observe' do
    it 'records durations of observed operations' do
      loggable_data = {
        'pipeline_creation_duration_s' => {
          'avg' => 30, 'count' => 1, 'max' => 30, 'min' => 30
        }
      }

      expect(logger.observe(:pipeline_creation_duration_s, 30)).to be_truthy
      expect(logger.observations_hash).to match(a_hash_including(loggable_data))
    end
  end

  describe '#commit' do
    subject(:commit) { logger.commit(pipeline: pipeline, caller: 'source') }

    before do
      stub_feature_flags(ci_pipeline_creation_logger: flag)
      allow(logger).to receive(:current_monotonic_time) { Time.current.to_i }

      logger.instrument(:pipeline_save) { travel(60.seconds) }
      logger.observe(:pipeline_creation_duration_s, 30)
      logger.observe(:pipeline_creation_duration_s, 10)
    end

    context 'when the feature flag is enabled' do
      let(:flag) { true }

      let(:loggable_data) do
        {
          'class' => described_class.name.to_s,
          'pipeline_id' => pipeline.id,
          'pipeline_persisted' => true,
          'project_id' => project.id,
          'pipeline_creation_service_duration_s' => a_kind_of(Numeric),
          'pipeline_creation_caller' => 'source',
          'pipeline_source' => pipeline.source,
          'pipeline_save_duration_s' => {
            'avg' => 60, 'count' => 1, 'max' => 60, 'min' => 60
          },
          'pipeline_creation_duration_s' => {
            'avg' => 20, 'count' => 2, 'max' => 30, 'min' => 10
          }
        }
      end

      it 'logs to application.json' do
        expect(Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(a_hash_including(loggable_data))
          .and_call_original

        expect(commit).to be_truthy
      end

      context 'with log conditions' do
        it 'does not log when the conditions are false' do
          logger.log_when { |_obs| false }

          expect(Gitlab::AppJsonLogger).not_to receive(:info)

          expect(commit).to be_falsey
        end

        it 'logs when a condition is true' do
          logger.log_when { |_obs| true }
          logger.log_when { |_obs| false }

          expect(Gitlab::AppJsonLogger)
            .to receive(:info)
            .with(a_hash_including(loggable_data))
            .and_call_original

          expect(commit).to be_truthy
        end
      end
    end

    context 'when the feature flag is disabled' do
      let(:flag) { false }

      it 'does not log' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        expect(commit).to be_falsey
      end
    end
  end
end
