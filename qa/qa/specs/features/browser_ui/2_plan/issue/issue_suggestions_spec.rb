# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'issue suggestions' do
      let(:issue_title) { 'Issue Lists are awesome' }

      before do
        Flow::Login.sign_in

        Resource::Issue.fabricate_via_api! do |issue|
          issue.title = issue_title
        end.project.visit!
      end

      it 'shows issue suggestions when creating a new issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347995' do
        Page::Project::Show.perform(&:go_to_new_issue)
        Page::Project::Issue::New.perform do |new_page|
          new_page.fill_title("issue")
          expect(new_page).to have_content(issue_title)

          new_page.fill_title("Issue Board")
          expect(new_page).not_to have_content(issue_title)
        end
      end
    end
  end
end
