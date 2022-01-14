# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :requires_admin do # remove :requires_admin once the ff is enabled by default in https://gitlab.com/gitlab-org/gitlab/-/issues/345398
    context 'Content Editor' do
      let(:initial_wiki) { Resource::Wiki::ProjectPage.fabricate_via_api! }
      let(:page_title) { 'Content Editor Page' }
      let(:heading_text) { 'My New Heading' }
      let(:image_file_name) { 'testfile.png' }
      let!(:toggle) { Runtime::Feature.enabled?(:wiki_switch_between_content_editor_raw_markdown) }

      before do
        Flow::Login.sign_in
      end

      after do
        initial_wiki.project.remove_via_api!
      end

      it 'creates a formatted Wiki page with an image uploaded', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347640' do
        initial_wiki.visit!

        Page::Project::Wiki::Show.perform(&:click_new_page)

        Page::Project::Wiki::Edit.perform do |edit|
          edit.set_title(page_title)
          edit.use_new_editor(toggle)
          edit.add_heading('Heading 1', heading_text)
          edit.upload_image(File.absolute_path(File.join('qa', 'fixtures', 'designs', image_file_name)))
        end

        Page::Project::Wiki::Edit.perform(&:click_submit)

        Page::Project::Wiki::Show.perform do |wiki|
          aggregate_failures 'page shows expected content' do
            expect(wiki).to have_title(page_title)
            expect(wiki).to have_heading('h1', heading_text)
            expect(wiki).to have_image(image_file_name)
          end
        end
      end
    end
  end
end
