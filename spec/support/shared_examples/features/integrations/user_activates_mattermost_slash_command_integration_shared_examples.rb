# frozen_string_literal: true

RSpec.shared_examples 'user activates the Mattermost Slash Command integration' do
  it 'shows a help message' do
    expect(page).to have_content('Use this service to perform common')
  end

  it 'shows a token placeholder' do
    token_placeholder = find_field('service_token')['placeholder']

    expect(token_placeholder).to eq('XXxxXXxxXXxxXXxxXXxxXXxx')
  end

  it 'redirects to the integrations page after saving but not activating' do
    token = ('a'..'z').to_a.join

    fill_in 'service_token', with: token
    click_active_checkbox
    click_save_integration

    expect(current_path).to eq(edit_path)
    expect(page).to have_content('Mattermost slash commands settings saved, but not active.')
  end

  it 'redirects to the integrations page after activating' do
    token = ('a'..'z').to_a.join

    fill_in 'service_token', with: token
    click_save_integration

    expect(current_path).to eq(edit_path)
    expect(page).to have_content('Mattermost slash commands settings saved and active.')
  end
end
