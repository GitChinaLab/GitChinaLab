# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StageEventHash, type: :model do
  let(:stage_event_hash) { described_class.create!(hash_sha256: hash_sha256) }
  let(:hash_sha256) { 'does_not_matter' }

  describe 'associations' do
    it { is_expected.to have_many(:cycle_analytics_project_stages) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:hash_sha256) }
  end

  describe '.record_id_by_hash_sha256' do
    it 'returns an existing id' do
      id = stage_event_hash.id
      same_id = described_class.record_id_by_hash_sha256(hash_sha256)

      expect(same_id).to eq(id)
    end

    it 'creates a new record' do
      expect do
        described_class.record_id_by_hash_sha256(hash_sha256)
      end.to change { described_class.count }.from(0).to(1)
    end
  end

  describe '.cleanup_if_unused' do
    it 'removes the record' do
      described_class.cleanup_if_unused(stage_event_hash.id)

      expect(described_class.find_by_id(stage_event_hash.id)).to be_nil
    end

    it 'does not remove the record' do
      id = create(:cycle_analytics_project_stage).stage_event_hash_id

      described_class.cleanup_if_unused(id)

      expect(described_class.find_by_id(id)).not_to be_nil
    end
  end
end
