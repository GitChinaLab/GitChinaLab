# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectGroupLink do
  describe "Associations" do
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }
  end

  describe "Validation" do
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }
    let(:project) { create(:project, group: group) }
    let!(:project_group_link) { create(:project_group_link, project: project) }

    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_uniqueness_of(:group_id).scoped_to(:project_id).with_message(/already shared/) }
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:group_access) }

    it "doesn't allow a project to be shared with the group it is in" do
      project_group_link.group = group

      expect(project_group_link).not_to be_valid
    end

    it "doesn't allow a project to be shared with an ancestor of the group it is in" do
      project_group_link.group = parent_group

      expect(project_group_link).not_to be_valid
    end
  end

  describe 'scopes' do
    describe '.non_guests' do
      let!(:project_group_link_reporter) { create :project_group_link, :reporter }
      let!(:project_group_link_maintainer) { create :project_group_link, :maintainer }
      let!(:project_group_link_developer) { create :project_group_link }
      let!(:project_group_link_guest) { create :project_group_link, :guest }

      it 'returns all records which are greater than Guests access' do
        expect(described_class.non_guests).to match_array([
                                                           project_group_link_reporter,
                                                           project_group_link_developer,
                                                           project_group_link_maintainer
                                                          ])
      end
    end
  end

  describe 'search by group name' do
    let_it_be(:project_group_link) { create(:project_group_link) }
    let_it_be(:group) { project_group_link.group }

    it { expect(described_class.search(group.name)).to eq([project_group_link]) }
    it { expect(described_class.search('not-a-group-name')).to be_empty }
  end
end
