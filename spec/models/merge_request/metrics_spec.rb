# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::Metrics do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:target_project).class_name('Project') }
    it { is_expected.to belong_to(:latest_closed_by).class_name('User') }
    it { is_expected.to belong_to(:merged_by).class_name('User') }
  end

  describe 'scopes' do
    let_it_be(:metrics_1) { create(:merge_request).metrics.tap { |m| m.update!(merged_at: 10.days.ago) } }
    let_it_be(:metrics_2) { create(:merge_request).metrics.tap { |m| m.update!(merged_at: 5.days.ago) } }

    describe '.merged_after' do
      subject { described_class.merged_after(7.days.ago) }

      it 'finds the record' do
        is_expected.to eq([metrics_2])
      end

      it "doesn't include record outside of the filter" do
        is_expected.not_to include([metrics_1])
      end
    end

    describe '.merged_before' do
      subject { described_class.merged_before(7.days.ago) }

      it 'finds the record' do
        is_expected.to eq([metrics_1])
      end

      it "doesn't include record outside of the filter" do
        is_expected.not_to include([metrics_2])
      end
    end

    describe '.by_target_project' do
      let(:target_project) { metrics_1.target_project }

      subject { described_class.by_target_project(target_project) }

      it 'finds metrics record with the associated target project' do
        is_expected.to eq([metrics_1])
      end
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:merge_request) { create(:merge_request) }
    let!(:parent) { create(:ci_pipeline, project: merge_request.target_project) }
    let!(:model) { merge_request.metrics.tap { |metrics| metrics.update!(pipeline: parent) } }
  end
end
