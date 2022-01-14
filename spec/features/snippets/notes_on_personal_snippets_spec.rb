# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comments on personal snippets', :js do
  include NoteInteractionHelpers

  let_it_be(:snippet) { create(:personal_snippet, :public) }
  let_it_be(:other_note) { create(:note_on_personal_snippet) }

  let(:user_name) { 'Test User' }
  let!(:user) { create(:user, name: user_name) }
  let!(:snippet_notes) do
    [
      create(:note_on_personal_snippet, noteable: snippet, author: user),
      create(:note_on_personal_snippet, noteable: snippet)
    ]
  end

  before do
    stub_feature_flags(bootstrap_confirmation_modals: false)
    sign_in user
    visit snippet_path(snippet)

    wait_for_requests
  end

  subject { page }

  context 'when viewing the snippet detail page' do
    it 'contains notes for a snippet with correct action icons' do
      expect(page).to have_selector('#notes-list li', count: 2)

      open_more_actions_dropdown(snippet_notes[0])

      # comment authored by current user
      page.within("#notes-list li#note_#{snippet_notes[0].id}") do
        expect(page).to have_content(snippet_notes[0].note)
        expect(page).to have_selector('.js-note-delete')
        expect(page).to have_selector('.note-emoji-button')
      end

      find('body').click # close dropdown
      open_more_actions_dropdown(snippet_notes[1])

      page.within("#notes-list li#note_#{snippet_notes[1].id}") do
        expect(page).to have_content(snippet_notes[1].note)
        expect(page).not_to have_selector('.js-note-delete')
        expect(page).to have_selector('.note-emoji-button')
      end
    end

    it 'shows the status of a note author' do
      status = create(:user_status, user: user)
      visit snippet_path(snippet)

      within("#note_#{snippet_notes[0].id}") do
        expect(page).to show_user_status(status)
      end
    end

    it 'shows the author name' do
      visit snippet_path(snippet)

      within("#note_#{snippet_notes[0].id}") do
        expect(page).to have_content(user_name)
      end
    end
  end

  context 'when submitting a note' do
    it 'shows a valid form' do
      is_expected.to have_css('.js-main-target-form', visible: true, count: 1)
      expect(find('.js-main-target-form .js-comment-button button', match: :first))
        .to have_content('Comment')

      page.within('.js-main-target-form') do
        expect(page).not_to have_link('Cancel')
      end
    end

    it 'previews a note' do
      fill_in 'note[note]', with: 'This is **awesome**!'
      find('.js-md-preview-button').click

      page.within('.new-note .md-preview-holder') do
        expect(page).to have_content('This is awesome!')
        expect(page).to have_selector('strong')
      end
    end

    it 'creates a note' do
      fill_in 'note[note]', with: 'This is **awesome**!'
      click_button 'Comment'

      expect(find('div#notes')).to have_content('This is awesome!')
    end

    it 'does not have autocomplete' do
      fill_in 'note[note]', with: '@'

      wait_for_requests

      # This selector probably won't be in place even if autocomplete was enabled
      # but we want to make sure
      expect(page).not_to have_selector('.atwho-view')
    end

    it_behaves_like 'personal snippet with references' do
      let(:container) { 'div#notes' }

      subject do
        fill_in 'note[note]', with: references
        click_button 'Comment'

        wait_for_requests
      end
    end
  end

  context 'when editing a note' do
    it 'changes the text' do
      find('.js-note-edit').click

      page.within('.current-note-edit-form') do
        fill_in 'note[note]', with: 'new content'
        find('.btn-success').click
      end

      page.within("#notes-list li#note_#{snippet_notes[0].id}") do
        edited_text = find('.edited-text')

        expect(page).to have_css('.note_edited_ago')
        expect(page).to have_content('new content')
        expect(edited_text).to have_selector('.note_edited_ago')
      end
    end
  end

  context 'when deleting a note' do
    it 'removes the note from the snippet detail page' do
      open_more_actions_dropdown(snippet_notes[0])

      page.within("#notes-list li#note_#{snippet_notes[0].id}") do
        accept_confirm { click_on 'Delete comment' }
      end

      wait_for_requests

      expect(page).not_to have_selector("#notes-list li#note_#{snippet_notes[0].id}")
    end
  end
end
