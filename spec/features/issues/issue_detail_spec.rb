# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Detail', :js do
  let_it_be_with_refind(:project) { create(:project, :public) }

  let(:user)     { create(:user) }
  let(:issue)    { create(:issue, project: project, author: user) }
  let(:incident) { create(:incident, project: project, author: user) }

  context 'when user displays the issue' do
    before do
      visit project_issue_path(project, issue)
      wait_for_requests
    end

    it 'shows the issue' do
      page.within('.issuable-details') do
        expect(find('h2')).to have_content(issue.title)
      end
    end
  end

  context 'when user displays the issue as an incident' do
    before do
      visit project_issue_path(project, incident)
      wait_for_requests
    end

    it 'does not show design management' do
      expect(page).not_to have_selector('.js-design-management')
    end
  end

  context 'when issue description has emojis' do
    let(:issue) { create(:issue, project: project, author: user, description: 'hello world :100:') }

    before do
      sign_in(user)
      visit project_issue_path(project, issue)
    end

    it 'renders gl-emoji tag' do
      page.within('.description') do
        expect(page).to have_selector('gl-emoji', count: 1)
      end
    end
  end

  context 'when issue description has xss snippet' do
    before do
      issue.update!(description: '![xss" onload=alert(1);//](a)')

      sign_in(user)
      visit project_issue_path(project, issue)
    end

    it 'encodes the description to prevent xss issues', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/207951' do
      page.within('.issuable-details .detail-page-description') do
        image = find('img.js-lazy-loaded')

        expect(page).to have_selector('img', count: 1)
        expect(image['onerror']).to be_nil
        expect(image['src']).to end_with('/a')
      end
    end
  end

  context 'when edited by a user who is later deleted' do
    before do
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_requests

      click_button 'Edit title and description'
      fill_in 'issuable-title', with: 'issue title'
      click_button 'Save changes'
      wait_for_requests

      Users::DestroyService.new(user).execute(user)

      visit project_issue_path(project, issue)
    end

    it 'shows the issue' do
      page.within('.issuable-details') do
        expect(find('h2')).to have_content(issue.reload.title)
      end
    end
  end

  describe 'user updates `issue_type` via the issue type dropdown' do
    let_it_be(:reporter) { create(:user) }

    before_all do
      project.add_reporter(reporter)
    end

    describe 'when an issue `issue_type` is edited' do
      before do
        sign_in(user)

        visit project_issue_path(project, issue)
        wait_for_requests
      end

      context 'by non-member author' do
        it 'cannot see Incident option' do
          open_issue_edit_form

          page.within('[data-testid="issuable-form"]') do
            expect(page).to have_content('Issue')
            expect(page).not_to have_content('Incident')
          end
        end
      end

      context 'by reporter' do
        let(:user) { reporter }

        it 'routes the user to the incident details page when the `issue_type` is set to incident' do
          open_issue_edit_form

          page.within('[data-testid="issuable-form"]') do
            update_type_select('Issue', 'Incident')

            expect(page).to have_current_path(project_issues_incident_path(project, issue))
          end
        end
      end
    end

    describe 'when an incident `issue_type` is edited' do
      before do
        sign_in(user)

        visit project_issue_path(project, incident)
        wait_for_requests
      end

      context 'by non-member author' do
        it 'routes the user to the issue details page when the `issue_type` is set to issue' do
          open_issue_edit_form

          page.within('[data-testid="issuable-form"]') do
            update_type_select('Incident', 'Issue')

            expect(page).to have_current_path(project_issue_path(project, incident))
          end
        end
      end

      context 'by reporter' do
        let(:user) { reporter }

        it 'routes the user to the issue details page when the `issue_type` is set to issue' do
          open_issue_edit_form

          page.within('[data-testid="issuable-form"]') do
            update_type_select('Incident', 'Issue')

            expect(page).to have_current_path(project_issue_path(project, incident))
          end
        end
      end
    end
  end

  def update_type_select(from, to)
    click_button from
    click_button to
    click_button 'Save changes'

    wait_for_requests
  end

  def open_issue_edit_form
    wait_for_requests
    click_button 'Edit title and description'
    wait_for_requests
  end
end
