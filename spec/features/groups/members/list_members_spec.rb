# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > List members', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user1) { create(:user, name: 'John Doe') }
  let(:user2) { create(:user, name: 'Mary Jane') }
  let(:group) { create(:group) }
  let(:nested_group) { create(:group, parent: group) }

  before do
    sign_in(user1)
  end

  it 'show members from current group and parent' do
    group.add_developer(user1)
    nested_group.add_developer(user2)

    visit group_group_members_path(nested_group)

    expect(first_row.text).to include(user1.name)
    expect(second_row.text).to include(user2.name)
  end

  it 'show user once if member of both current group and parent' do
    group.add_developer(user1)
    nested_group.add_developer(user1)

    visit group_group_members_path(nested_group)

    expect(first_row.text).to include(user1.name)
    expect(second_row).to be_blank
  end

  describe 'showing status of members' do
    before do
      group.add_developer(user2)
    end

    it 'shows the status' do
      create(:user_status, user: user2, emoji: 'smirk', message: 'Authoring this object')

      visit group_group_members_path(nested_group)

      expect(first_row).to have_selector('gl-emoji[data-name="smirk"]')
    end
  end

  describe 'when user has 2FA enabled' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:user_with_2fa) { create(:user, :two_factor_via_otp) }

    before do
      group.add_guest(user_with_2fa)
    end

    it 'shows 2FA badge to user with "Owner" access level' do
      group.add_owner(user1)

      visit group_group_members_path(group)

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end

    it 'shows 2FA badge to admins' do
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)

      visit group_group_members_path(group)

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end

    it 'does not show 2FA badge to users with access level below "Owner"' do
      group.add_maintainer(user1)

      visit group_group_members_path(group)

      expect(find_member_row(user_with_2fa)).not_to have_content('2FA')
    end

    it 'shows 2FA badge to themselves' do
      sign_in(user_with_2fa)

      visit group_group_members_path(group)

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end
  end
end
