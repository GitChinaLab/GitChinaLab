# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::GroupPolicyPreloader do
  let_it_be(:user) { create(:user) }
  let_it_be(:root_parent) { create(:group, :private, name: 'root-1', path: 'root-1') }
  let_it_be(:guest_group) { create(:group, name: 'public guest', path: 'public-guest') }
  let_it_be(:private_maintainer_group) { create(:group, :private, name: 'b private maintainer', path: 'b-private-maintainer', parent: root_parent) }
  let_it_be(:private_developer_group) { create(:group, :private, project_creation_level: nil, name: 'c public developer', path: 'c-public-developer') }
  let_it_be(:public_maintainer_group) { create(:group, :private, name: 'a public maintainer', path: 'a-public-maintainer') }

  let(:base_groups) { [guest_group, private_maintainer_group, private_developer_group, public_maintainer_group] }

  before_all do
    guest_group.add_guest(user)
    private_maintainer_group.add_maintainer(user)
    private_developer_group.add_developer(user)
    public_maintainer_group.add_maintainer(user)
  end

  it 'avoids N+1 queries when authorizing a list of groups', :request_store do
    preload_groups_for_policy(user)
    control = ActiveRecord::QueryRecorder.new { authorize_all_groups(user) }

    new_group1 = create(:group, :private).tap { |group| group.add_maintainer(user) }
    new_group2 = create(:group, :private, parent: private_maintainer_group)

    another_root = create(:group, :private, name: 'root-3', path: 'root-3')
    new_group3 = create(:group, :private, parent: another_root).tap { |group| group.add_maintainer(user) }

    pristine_groups = Group.where(id: base_groups + [new_group1, new_group2, new_group3])

    preload_groups_for_policy(user, pristine_groups)
    expect { authorize_all_groups(user, pristine_groups) }.not_to exceed_query_limit(control)
  end

  def authorize_all_groups(current_user, group_list = base_groups)
    group_list.each { |group| current_user.can?(:read_group, group) }
  end

  def preload_groups_for_policy(current_user, group_list = base_groups)
    described_class.new(group_list, current_user).execute
  end
end
