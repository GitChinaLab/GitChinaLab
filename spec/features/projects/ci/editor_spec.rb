# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline Editor', :js do
  include Spec::Support::Helpers::Features::SourceEditorSpecHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  let(:default_branch) { 'main' }
  let(:other_branch) { 'test' }

  before do
    sign_in(user)
    project.add_developer(user)

    project.repository.create_file(user, project.ci_config_path_or_default, 'Default Content', message: 'Create CI file for main', branch_name: default_branch)
    project.repository.create_file(user, project.ci_config_path_or_default, 'Other Content', message: 'Create CI file for test', branch_name: other_branch)

    visit project_ci_pipeline_editor_path(project)
    wait_for_requests
  end

  it 'user sees the Pipeline Editor page' do
    expect(page).to have_content('Pipeline Editor')
  end

  context 'branch switcher' do
    def switch_to_branch(branch)
      find('[data-testid="branch-selector"]').click

      page.within '[data-testid="branch-selector"]' do
        click_button branch
        wait_for_requests
      end
    end

    it 'displays current branch' do
      page.within('[data-testid="branch-selector"]') do
        expect(page).to have_content(default_branch)
        expect(page).not_to have_content(other_branch)
      end
    end

    it 'displays updated current branch after switching branches' do
      switch_to_branch(other_branch)

      page.within('[data-testid="branch-selector"]') do
        expect(page).to have_content(other_branch)
        expect(page).not_to have_content(default_branch)
      end
    end

    it 'displays new branch as selected after commiting on a new branch' do
      find('#target-branch-field').set('new_branch', clear: :backspace)

      click_button 'Commit changes'

      page.within('[data-testid="branch-selector"]') do
        expect(page).to have_content('new_branch')
        expect(page).not_to have_content(default_branch)
      end
    end
  end

  context 'Editor content' do
    it 'user can reset their CI configuration' do
      click_button 'Collapse'

      page.within('#source-editor-') do
        find('textarea').send_keys '123'
      end

      # It takes some time after sending keys for the reset
      # btn to register the changes inside the editor
      sleep 1
      click_button 'Reset'

      expect(page).to have_css('#reset-content')

      page.within('#reset-content') do
        click_button 'Reset file'
      end

      page.within('#source-editor-') do
        expect(page).to have_content('Default Content')
        expect(page).not_to have_content('Default Content123')
      end
    end

    it 'user can cancel reseting their CI configuration' do
      click_button 'Collapse'

      page.within('#source-editor-') do
        find('textarea').send_keys '123'
      end

      # It takes some time after sending keys for the reset
      # btn to register the changes inside the editor
      sleep 1
      click_button 'Reset'

      expect(page).to have_css('#reset-content')

      page.within('#reset-content') do
        click_button 'Cancel'
      end

      page.within('#source-editor-') do
        expect(page).to have_content('Default Content123')
      end
    end
  end
end
