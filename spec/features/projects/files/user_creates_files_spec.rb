# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User creates files', :js do
  include BlobSpecHelpers

  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end

  let(:project) { create(:project, :repository, name: 'Shop') }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project_tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'without committing a new file' do
    context 'when an user has write access' do
      before do
        visit(project_tree_path_root_ref)
      end

      it 'opens new file page' do
        find('.add-to-tree').click
        click_link('New file')

        expect(page).to have_content('New file')
        expect(page).to have_content('Commit message')
      end
    end

    context 'when an user does not have write access' do
      before do
        project2.add_reporter(user)
        visit(project2_tree_path_root_ref)
      end

      it 'opens new file page on a forked project', :sidekiq_might_not_need_inline do
        find('.add-to-tree').click
        click_link('New file')

        expect(page).to have_selector('.file-editor')
        expect(page).to have_content(fork_message)
        expect(page).to have_content('New file')
        expect(page).to have_content('Commit message')
      end
    end
  end

  context 'with committing a new file' do
    context 'when an user has write access' do
      before do
        visit(project_tree_path_root_ref)

        find('.add-to-tree').click
        click_link('New file')
        expect(page).to have_selector('.file-editor')
      end

      def submit_new_file(options)
        file_name = find('#file_name')
        file_name.set options[:file_name] || 'README.md'

        find('.monaco-editor textarea').send_keys.native.send_keys options[:file_content] || 'Some content'

        click_button 'Commit changes'
      end

      it 'allows Chinese characters in file name' do
        submit_new_file(file_name: '测试.md')
        expect(page).to have_content 'The file has been successfully created.'
      end

      it 'allows Chinese characters in directory name' do
        submit_new_file(file_name: '中文/测试.md')
        expect(page).to have_content 'The file has been successfully created'
      end

      it 'does not allow directory traversal in file name' do
        submit_new_file(file_name: '../README.md')
        expect(page).to have_content 'Path cannot include directory traversal'
      end

      it 'creates and commit a new file' do
        find('#editor')
        execute_script("monaco.editor.getModels()[0].setValue('*.rbca')")
        fill_in(:file_name, with: 'not_a_file.md')
        fill_in(:commit_message, with: 'New commit message', visible: true)
        click_button('Commit changes')

        new_file_path = project_blob_path(project, 'master/not_a_file.md')

        expect(current_path).to eq(new_file_path)

        wait_for_requests

        expect(page).to have_content('*.rbca')
      end

      it 'creates and commit a new file with new lines at the end of file' do
        set_default_button('edit')

        find('#editor')
        execute_script('monaco.editor.getModels()[0].setValue("Sample\n\n\n")')
        fill_in(:file_name, with: 'not_a_file.md')
        fill_in(:commit_message, with: 'New commit message', visible: true)
        click_button('Commit changes')

        new_file_path = project_blob_path(project, 'master/not_a_file.md')

        expect(current_path).to eq(new_file_path)

        click_link('Edit')

        find('#editor')
        expect(evaluate_script('monaco.editor.getModels()[0].getValue()')).to eq("Sample\n\n\n")
      end

      it 'creates and commit a new file with a directory name' do
        fill_in(:file_name, with: 'foo/bar/baz.txt')

        expect(page).to have_selector('.file-editor')

        find('#editor')
        execute_script("monaco.editor.getModels()[0].setValue('*.rbca')")
        fill_in(:commit_message, with: 'New commit message', visible: true)
        click_button('Commit changes')

        expect(current_path).to eq(project_blob_path(project, 'master/foo/bar/baz.txt'))

        wait_for_requests

        expect(page).to have_content('*.rbca')
      end

      it 'creates and commit a new file specifying a new branch' do
        expect(page).to have_selector('.file-editor')

        find('#editor')
        execute_script("monaco.editor.getModels()[0].setValue('*.rbca')")
        fill_in(:file_name, with: 'not_a_file.md')
        fill_in(:commit_message, with: 'New commit message', visible: true)
        fill_in(:branch_name, with: 'new_branch_name', visible: true)
        click_button('Commit changes')

        expect(current_path).to eq(project_new_merge_request_path(project))

        click_link('Changes')

        wait_for_requests

        expect(page).to have_content('*.rbca')
      end
    end

    context 'when an user does not have write access', :sidekiq_might_not_need_inline do
      before do
        project2.add_reporter(user)
        visit(project2_tree_path_root_ref)

        find('.add-to-tree').click
        click_link('New file')
      end

      it 'shows a message saying the file will be committed in a fork' do
        message = "GitLab will create a branch in your fork and start a merge request."

        expect(page).to have_content(message)
      end

      it 'creates and commit new file in forked project' do
        expect(page).to have_selector('.file-editor')

        find('#editor')
        execute_script("monaco.editor.getModels()[0].setValue('*.rbca')")

        fill_in(:file_name, with: 'not_a_file.md')
        fill_in(:commit_message, with: 'New commit message', visible: true)
        click_button('Commit changes')

        fork = user.fork_of(project2.reload)

        expect(current_path).to eq(project_new_merge_request_path(fork))
        expect(page).to have_content('New commit message')
      end
    end
  end
end
