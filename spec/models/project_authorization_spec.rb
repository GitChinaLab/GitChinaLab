# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAuthorization do
  describe 'relations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.all_values) }
  end

  describe '.insert_all' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }

    it 'skips duplicates and inserts the remaining rows without error' do
      create(:project_authorization, user: user, project: project_1, access_level: Gitlab::Access::MAINTAINER)

      attributes = [
        { user_id: user.id, project_id: project_1.id, access_level: Gitlab::Access::MAINTAINER },
        { user_id: user.id, project_id: project_2.id, access_level: Gitlab::Access::MAINTAINER },
        { user_id: user.id, project_id: project_3.id, access_level: Gitlab::Access::MAINTAINER }
      ]

      described_class.insert_all(attributes)

      expect(user.project_authorizations.pluck(:user_id, :project_id, :access_level)).to match_array(attributes.map(&:values))
    end
  end

  describe '.insert_all_in_batches' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_3) { create(:project) }

    let(:per_batch_size) { 2 }

    it 'inserts the rows in batches, as per the `per_batch` size' do
      attributes = [
        { user_id: user.id, project_id: project_1.id, access_level: Gitlab::Access::MAINTAINER },
        { user_id: user.id, project_id: project_2.id, access_level: Gitlab::Access::MAINTAINER },
        { user_id: user.id, project_id: project_3.id, access_level: Gitlab::Access::MAINTAINER }
      ]

      expect(described_class).to receive(:insert_all).twice.and_call_original

      described_class.insert_all_in_batches(attributes, per_batch_size)

      expect(user.project_authorizations.pluck(:user_id, :project_id, :access_level)).to match_array(attributes.map(&:values))
    end
  end
end
