# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ResourceGroup do
  describe 'validation' do
    it 'valids when key includes allowed character' do
      resource_group = build(:ci_resource_group, key: 'test')

      expect(resource_group).to be_valid
    end

    it 'invalids when key includes invalid character' do
      resource_group = build(:ci_resource_group, key: ':::')

      expect(resource_group).not_to be_valid
    end
  end

  describe '#ensure_resource' do
    it 'creates one resource when resource group is created' do
      resource_group = create(:ci_resource_group)

      expect(resource_group.resources.count).to eq(1)
      expect(resource_group.resources.all?(&:persisted?)).to eq(true)
    end
  end

  describe '#assign_resource_to' do
    subject { resource_group.assign_resource_to(build) }

    let(:build) { create(:ci_build) }
    let(:resource_group) { create(:ci_resource_group) }

    it 'retains resource for the processable' do
      expect(resource_group.resources.first.processable).to be_nil

      is_expected.to eq(true)

      expect(resource_group.resources.first.processable).to eq(build)
    end

    context 'when there are no free resources' do
      before do
        resource_group.assign_resource_to(create(:ci_build))
      end

      it 'fails to retain resource' do
        is_expected.to eq(false)
      end
    end

    context 'when the build has already retained a resource' do
      let!(:another_resource) { create(:ci_resource, resource_group: resource_group, processable: build) }

      it 'fails to retain resource' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe '#release_resource_from' do
    subject { resource_group.release_resource_from(build) }

    let(:build) { create(:ci_build) }
    let(:resource_group) { create(:ci_resource_group) }

    context 'when the build has already retained a resource' do
      before do
        resource_group.assign_resource_to(build)
      end

      it 'releases resource from the build' do
        expect(resource_group.resources.first.processable).to eq(build)

        is_expected.to eq(true)

        expect(resource_group.resources.first.processable).to be_nil
      end
    end

    context 'when the build has already released a resource' do
      it 'fails to release resource' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#upcoming_processables' do
    subject { resource_group.upcoming_processables }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline_1) { create(:ci_pipeline, project: project) }
    let_it_be(:pipeline_2) { create(:ci_pipeline, project: project) }

    let!(:resource_group) { create(:ci_resource_group, process_mode: process_mode, project: project) }

    Ci::HasStatus::STATUSES_ENUM.keys.each do |status|
      let!("build_1_#{status}") { create(:ci_build, pipeline: pipeline_1, status: status, resource_group: resource_group) }
      let!("build_2_#{status}") { create(:ci_build, pipeline: pipeline_2, status: status, resource_group: resource_group) }
    end

    context 'when process mode is unordered' do
      let(:process_mode) { :unordered }

      it 'returns correct jobs in an indeterministic order' do
        expect(subject).to contain_exactly(build_1_waiting_for_resource, build_2_waiting_for_resource)
      end
    end

    context 'when process mode is oldest_first' do
      let(:process_mode) { :oldest_first }

      it 'returns correct jobs in a specific order' do
        expect(subject[0]).to eq(build_1_waiting_for_resource)
        expect(subject[1..2]).to contain_exactly(build_1_created, build_1_scheduled)
        expect(subject[3]).to eq(build_2_waiting_for_resource)
        expect(subject[4..5]).to contain_exactly(build_2_created, build_2_scheduled)
      end
    end

    context 'when process mode is newest_first' do
      let(:process_mode) { :newest_first }

      it 'returns correct jobs in a specific order' do
        expect(subject[0]).to eq(build_2_waiting_for_resource)
        expect(subject[1..2]).to contain_exactly(build_2_created, build_2_scheduled)
        expect(subject[3]).to eq(build_1_waiting_for_resource)
        expect(subject[4..5]).to contain_exactly(build_1_created, build_1_scheduled)
      end
    end

    context 'when process mode is unknown' do
      let(:process_mode) { :unordered }

      before do
        resource_group.update_column(:process_mode, 3)
      end

      it 'returns empty' do
        is_expected.to be_empty
      end
    end
  end
end
