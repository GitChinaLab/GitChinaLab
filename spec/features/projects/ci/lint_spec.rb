# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI Lint', :js do
  include Spec::Support::Helpers::Features::SourceEditorSpecHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  let(:content_selector) { '.content .view-lines' }

  before do
    project.add_developer(user)
    sign_in(user)

    visit project_ci_lint_path(project)
    editor_set_value(yaml_content)

    wait_for('YAML content') do
      find(content_selector).text.present?
    end
  end

  describe 'YAML parsing' do
    shared_examples 'validates the YAML' do
      before do
        click_on 'Validate'
      end

      context 'YAML is correct' do
        let(:yaml_content) do
          File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
        end

        it 'parses Yaml and displays the jobs' do
          expect(page).to have_content('Status: Syntax is correct')

          within "table" do
            aggregate_failures do
              expect(page).to have_content('Job - rspec')
              expect(page).to have_content('Job - spinach')
              expect(page).to have_content('Deploy Job - staging')
              expect(page).to have_content('Deploy Job - production')
            end
          end
        end
      end

      context 'YAML is incorrect' do
        let(:yaml_content) { 'value: cannot have :' }

        it 'displays information about an error' do
          expect(page).to have_content('Status: Syntax is incorrect')
          expect(page).to have_selector(content_selector, text: yaml_content)
        end
      end
    end

    it_behaves_like 'validates the YAML'

    context 'when Dry Run is checked' do
      before do
        check 'Simulate a pipeline created for the default branch'
      end

      it_behaves_like 'validates the YAML'
    end
  end

  describe 'YAML clearing' do
    before do
      click_on 'Clear'
    end

    context 'YAML is present' do
      let(:yaml_content) do
        File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
      end

      it 'YAML content is cleared' do
        expect(page).to have_field(class: 'inputarea', with: '', visible: false, type: 'textarea')
      end
    end
  end
end
