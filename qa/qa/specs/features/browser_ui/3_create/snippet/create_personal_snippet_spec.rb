# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do # convert back to a smoke test once proved to be stable
    describe 'Personal snippet creation' do
      let(:snippet) do
        Resource::Snippet.fabricate_via_browser_ui! do |snippet|
          snippet.title = 'Snippet title'
          snippet.description = 'Snippet description'
          snippet.visibility = 'Private'
          snippet.file_name = 'ruby_file.rb'
          snippet.file_content = 'File.read("test.txt").split(/\n/)'
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        snippet.remove_via_api!
      end

      it 'user creates a personal snippet', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347799' do
        snippet.visit!

        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_snippet_title('Snippet title')
          expect(snippet).to have_snippet_description('Snippet description')
          expect(snippet).to have_visibility_type(/private/i)
          expect(snippet).to have_file_name('ruby_file.rb')
          expect(snippet).to have_file_content('File.read("test.txt").split(/\n/)')
          expect(snippet).to have_syntax_highlighting('ruby')
        end
      end
    end
  end
end
