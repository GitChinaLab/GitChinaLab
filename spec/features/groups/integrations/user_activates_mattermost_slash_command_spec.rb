# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates the group-level Mattermost Slash Command integration', :js do
  include_context 'group integration activation'

  before do
    stub_mattermost_setting(enabled: true)
    visit_group_integration('Mattermost slash commands')
  end

  let(:edit_path) { edit_group_settings_integration_path(group, :mattermost_slash_commands) }

  include_examples 'user activates the Mattermost Slash Command integration'

  it 'does not display the overrides tab' do
    expect(page).not_to have_link('Settings', href: edit_path)
    expect(page).not_to have_link('Projects using custom settings', href: overrides_admin_application_settings_integration_path(:mattermost_slash_commands))
  end
end
