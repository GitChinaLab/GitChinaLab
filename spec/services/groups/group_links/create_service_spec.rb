# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinks::CreateService, '#execute' do
  let(:parent_group_user) { create(:user) }
  let(:group_user) { create(:user) }
  let(:child_group_user) { create(:user) }
  let(:prevent_sharing) { false }

  let_it_be(:group_parent) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: group_parent) }
  let_it_be(:group_child) { create(:group, :private, parent: group) }

  let(:ns_for_parent) { create(:namespace_settings, prevent_sharing_groups_outside_hierarchy: prevent_sharing) }
  let(:shared_group_parent) { create(:group, :private, namespace_settings: ns_for_parent) }
  let(:shared_group) { create(:group, :private, parent: shared_group_parent) }
  let(:shared_group_child) { create(:group, :private, parent: shared_group) }

  let(:project_parent) { create(:project, group: shared_group_parent) }
  let(:project) { create(:project, group: shared_group) }
  let(:project_child) { create(:project, group: shared_group_child) }

  let(:opts) do
    {
      shared_group_access: Gitlab::Access::DEVELOPER,
      expires_at: nil
    }
  end

  let(:user) { group_user }

  subject { described_class.new(shared_group, group, user, opts) }

  before do
    group.add_guest(group_user)
    shared_group.add_owner(group_user)
  end

  it 'adds group to another group' do
    expect { subject.execute }.to change { group.shared_group_links.count }.from(0).to(1)
  end

  it 'returns false if shared group is blank' do
    expect { described_class.new(nil, group, user, opts) }.not_to change { group.shared_group_links.count }
  end

  context 'user does not have access to group' do
    let(:user) { create(:user) }

    before do
      shared_group.add_owner(user)
    end

    it 'returns error' do
      result = subject.execute

      expect(result[:status]).to eq(:error)
      expect(result[:http_status]).to eq(404)
    end
  end

  context 'user does not have admin access to shared group' do
    let(:user) { create(:user) }

    before do
      group.add_guest(user)
      shared_group.add_developer(user)
    end

    it 'returns error' do
      result = subject.execute

      expect(result[:status]).to eq(:error)
      expect(result[:http_status]).to eq(404)
    end
  end

  context 'project authorizations based on group hierarchies' do
    before do
      group_parent.add_owner(parent_group_user)
      group.add_owner(group_user)
      group_child.add_owner(child_group_user)
    end

    context 'project authorizations refresh' do
      it 'is executed only for the direct members of the group' do
        expect(UserProjectAccessChangedService).to receive(:new).with(contain_exactly(group_user.id)).and_call_original

        subject.execute
      end
    end

    context 'project authorizations' do
      context 'group user' do
        let(:user) { group_user }

        it 'create proper authorizations' do
          subject.execute

          expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
          expect(Ability.allowed?(user, :read_project, project)).to be_truthy
          expect(Ability.allowed?(user, :read_project, project_child)).to be_truthy
        end
      end

      context 'parent group user' do
        let(:user) { parent_group_user }

        it 'create proper authorizations' do
          subject.execute

          expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
          expect(Ability.allowed?(user, :read_project, project)).to be_falsey
          expect(Ability.allowed?(user, :read_project, project_child)).to be_falsey
        end
      end

      context 'child group user' do
        let(:user) { child_group_user }

        it 'create proper authorizations' do
          subject.execute

          expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
          expect(Ability.allowed?(user, :read_project, project)).to be_falsey
          expect(Ability.allowed?(user, :read_project, project_child)).to be_falsey
        end
      end
    end
  end

  context 'sharing outside the hierarchy is disabled' do
    let(:prevent_sharing) { true }

    it 'prevents sharing with a group outside the hierarchy' do
      result = subject.execute

      expect(group.reload.shared_group_links.count).to eq(0)
      expect(result[:status]).to eq(:error)
      expect(result[:http_status]).to eq(404)
    end

    it 'allows sharing with a group within the hierarchy' do
      sibling_group = create(:group, :private, parent: shared_group_parent)
      sibling_group.add_guest(group_user)

      result = described_class.new(shared_group, sibling_group, user, opts).execute

      expect(sibling_group.reload.shared_group_links.count).to eq(1)
      expect(result[:status]).to eq(:success)
    end
  end
end
