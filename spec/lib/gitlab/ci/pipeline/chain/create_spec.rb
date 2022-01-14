# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Create do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master')
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project, current_user: user)
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when pipeline is ready to be saved' do
    before do
      pipeline.stages.build(name: 'test', position: 0, project: project)

      step.perform!
    end

    it 'saves a pipeline' do
      expect(pipeline).to be_persisted
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'creates stages' do
      expect(pipeline.reload.stages).to be_one
      expect(pipeline.stages.first).to be_persisted
    end
  end

  context 'when pipeline has validation errors' do
    let(:pipeline) do
      build(:ci_pipeline, project: project, ref: nil)
    end

    before do
      step.perform!
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'appends validation error' do
      expect(pipeline.errors.to_a)
        .to include /Failed to persist the pipeline/
    end
  end

  context 'tags persistence' do
    let(:stage) do
      build(:ci_stage_entity, pipeline: pipeline)
    end

    let(:job) do
      build(:ci_build, stage: stage, pipeline: pipeline, project: project)
    end

    let(:bridge) do
      build(:ci_bridge, stage: stage, pipeline: pipeline, project: project)
    end

    before do
      pipeline.stages = [stage]
      stage.statuses = [job, bridge]
    end

    context 'without tags' do
      it 'extracts an empty tag list' do
        expect(CommitStatus)
          .to receive(:bulk_insert_tags!)
          .with(stage.statuses, {})
          .and_call_original

        step.perform!

        expect(job.instance_variable_defined?(:@tag_list)).to be_falsey
        expect(job).to be_persisted
        expect(job.tag_list).to eq([])
      end
    end

    context 'with tags' do
      before do
        job.tag_list = %w[tag1 tag2]
      end

      it 'bulk inserts tags' do
        expect(CommitStatus)
          .to receive(:bulk_insert_tags!)
          .with(stage.statuses, { job.name => %w[tag1 tag2] })
          .and_call_original

        step.perform!

        expect(job.instance_variable_defined?(:@tag_list)).to be_falsey
        expect(job).to be_persisted
        expect(job.tag_list).to match_array(%w[tag1 tag2])
      end
    end

    context 'when the feature flag is disabled' do
      before do
        job.tag_list = %w[tag1 tag2]
        stub_feature_flags(ci_bulk_insert_tags: false)
      end

      it 'follows the old code path' do
        expect(CommitStatus).not_to receive(:bulk_insert_tags!)

        step.perform!

        expect(job.instance_variable_defined?(:@tag_list)).to be_truthy
        expect(job).to be_persisted
        expect(job.reload.tag_list).to match_array(%w[tag1 tag2])
      end
    end
  end
end
