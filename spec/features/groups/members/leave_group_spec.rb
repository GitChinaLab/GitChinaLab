# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Leave group' do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:group) { create(:group) }

  before do
    stub_feature_flags(bootstrap_confirmation_modals: false)
    sign_in(user)
  end

  it 'guest leaves the group' do
    group.add_guest(user)
    group.add_owner(other_user)

    visit group_path(group)
    click_link 'Leave group'

    expect(current_path).to eq(dashboard_groups_path)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  it 'guest leaves the group by url param', :js do
    group.add_guest(user)
    group.add_owner(other_user)

    visit group_path(group, leave: 1)

    page.accept_confirm

    wait_for_all_requests
    expect(current_path).to eq(dashboard_groups_path)
    expect(group.users).not_to include(user)
  end

  it 'guest leaves the group as last member' do
    group.add_guest(user)

    visit group_path(group)
    click_link 'Leave group'

    expect(current_path).to eq(dashboard_groups_path)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  it 'owner leaves the group if they are not the last owner' do
    group.add_owner(user)
    group.add_owner(other_user)

    visit group_path(group)
    click_link 'Leave group'

    expect(current_path).to eq(dashboard_groups_path)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  it 'owner can not leave the group if they are the last owner', :js do
    group.add_owner(user)

    visit group_path(group)

    expect(page).not_to have_content 'Leave group'

    visit group_group_members_path(group)

    expect(members_table).not_to have_selector 'button[title="Leave"]'
  end

  it 'owner can not leave the group by url param if they are the last owner', :js do
    group.add_owner(user)

    visit group_path(group, leave: 1)

    expect(find('.flash-alert')).to have_content 'You do not have permission to leave this group'
  end

  def left_group_message(group)
    "You left the \"#{group.name}\""
  end
end
