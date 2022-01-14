# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Topic show page' do
  let_it_be(:topic) { create(:topic, name: 'my-topic', description: 'This is **my** topic https://google.com/ :poop: ```\ncode\n```', avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png")) }

  context 'when topic does not exist' do
    let(:path) { topic_explore_projects_path(topic_name: 'non-existing') }

    it 'renders 404' do
      visit path

      expect(status_code).to eq(404)
    end
  end

  context 'when topic exists' do
    before do
      visit topic_explore_projects_path(topic_name: topic.name)
    end

    it 'shows name, avatar and description as markdown' do
      expect(page).to have_content(topic.name)
      expect(page).to have_selector('.avatar-container > img.topic-avatar')
      expect(find('.topic-description')).to have_selector('p > strong')
      expect(find('.topic-description')).to have_selector('p > a[rel]')
      expect(find('.topic-description')).to have_selector('p > gl-emoji')
      expect(find('.topic-description')).to have_selector('p > code')
    end

    context 'with associated projects' do
      let!(:project) { create(:project, :public, topic_list: topic.name) }

      it 'shows project list' do
        visit topic_explore_projects_path(topic_name: topic.name)

        expect(find('.projects-list .project-name')).to have_content(project.name)
      end
    end

    context 'without associated projects' do
      it 'shows correct empty state message' do
        expect(page).to have_content('Explore public groups to find projects to contribute to.')
      end
    end
  end
end
