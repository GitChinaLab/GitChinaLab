# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/edit' do
  include Devise::Test::ControllerHelpers
  include ProjectForksHelper

  let(:project) { create(:project) }
  let(:user) { create(:admin) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive_messages(current_user: user,
                                    can?: true,
                                    current_application_settings: Gitlab::CurrentSettings.current_application_settings)
  end

  context 'project export disabled' do
    it 'does not display the project export option' do
      stub_application_setting(project_export_enabled?: false)

      render

      expect(rendered).not_to have_content('Export project')
    end
  end

  context 'merge suggestions settings' do
    it 'displays all possible variables' do
      render

      expect(rendered).to have_content('%{branch_name}')
      expect(rendered).to have_content('%{files_count}')
      expect(rendered).to have_content('%{file_paths}')
      expect(rendered).to have_content('%{project_name}')
      expect(rendered).to have_content('%{project_path}')
      expect(rendered).to have_content('%{user_full_name}')
      expect(rendered).to have_content('%{username}')
      expect(rendered).to have_content('%{suggestions_count}')
    end

    it 'displays a placeholder if none is set' do
      render

      expect(rendered).to have_field('project[suggestion_commit_message]', placeholder: "Apply %{suggestions_count} suggestion(s) to %{files_count} file(s)")
    end

    it 'displays the user entered value' do
      project.update!(suggestion_commit_message: 'refactor: changed %{file_paths}')

      render

      expect(rendered).to have_field('project[suggestion_commit_message]', with: 'refactor: changed %{file_paths}')
    end
  end

  context 'merge commit template' do
    it 'displays all possible variables' do
      render

      expect(rendered).to have_content('%{source_branch}')
      expect(rendered).to have_content('%{target_branch}')
      expect(rendered).to have_content('%{title}')
      expect(rendered).to have_content('%{issues}')
      expect(rendered).to have_content('%{description}')
      expect(rendered).to have_content('%{reference}')
    end

    it 'displays a placeholder if none is set' do
      render

      expect(rendered).to have_field('project[merge_commit_template]', placeholder: <<~MSG.rstrip)
        Merge branch '%{source_branch}' into '%{target_branch}'

        %{title}

        %{issues}

        See merge request %{reference}
      MSG
    end

    it 'displays the user entered value' do
      project.update!(merge_commit_template: '%{title}')

      render

      expect(rendered).to have_field('project[merge_commit_template]', with: '%{title}')
    end
  end

  context 'squash template' do
    it 'displays a placeholder if none is set' do
      render

      expect(rendered).to have_field('project[squash_commit_template]', placeholder: '%{title}')
    end

    it 'displays the user entered value' do
      project.update!(squash_commit_template: '%{first_multiline_commit}')

      render

      expect(rendered).to have_field('project[squash_commit_template]', with: '%{first_multiline_commit}')
    end
  end

  context 'forking' do
    before do
      assign(:project, project)

      allow(view).to receive(:current_user).and_return(user)
    end

    context 'project is not a fork' do
      it 'hides the remove fork relationship settings' do
        render

        expect(rendered).not_to have_content('Remove fork relationship')
      end
    end

    context 'project is a fork' do
      let(:source_project) { create(:project) }
      let(:project) { fork_project(source_project) }

      it 'shows the remove fork relationship settings to an authorized user' do
        allow(view).to receive(:can?).with(user, :remove_fork_project, project).and_return(true)

        render

        expect(rendered).to have_content('Remove fork relationship')
        expect(rendered).to have_link(source_project.full_name, href: project_path(source_project))
      end

      it 'hides the fork relationship settings from an unauthorized user' do
        allow(view).to receive(:can?).with(user, :remove_fork_project, project).and_return(false)

        render

        expect(rendered).not_to have_content('Remove fork relationship')
      end

      it 'hides the fork source from an unauthorized user' do
        allow(view).to receive(:can?).with(user, :read_project, source_project).and_return(false)

        render

        expect(rendered).to have_content('Remove fork relationship')
        expect(rendered).not_to have_content(source_project.full_name)
      end

      it 'shows the fork source to an authorized user' do
        allow(view).to receive(:can?).with(user, :read_project, source_project).and_return(true)

        render

        expect(rendered).to have_content('Remove fork relationship')
        expect(rendered).to have_link(source_project.full_name, href: project_path(source_project))
      end
    end
  end
end
