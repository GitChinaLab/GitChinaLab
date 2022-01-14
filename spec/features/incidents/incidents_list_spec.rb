# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Management index', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }

  before_all do
    project.add_developer(developer)
  end

  before do
    sign_in(developer)

    visit project_incidents_path(project)
    wait_for_requests
  end

  context 'when a developer displays the incident list' do
    it 'shows the status tabs' do
      expect(page).to have_selector('.gl-tabs')
    end

    it 'shows the filtered search' do
      expect(page).to have_selector('.filtered-search-wrapper')
    end

    it 'shows the alert table' do
      expect(page).to have_selector('.gl-table')
    end

    it 'alert page title' do
      expect(page).to have_content('Incidents')
    end
  end
end
