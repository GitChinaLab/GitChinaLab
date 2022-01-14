# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Import/Export - GitLab migration history', :js do
  let_it_be(:user) { create(:user) }

  let_it_be(:user_import_1) { create(:bulk_import, user: user) }
  let_it_be(:finished_entity_1) { create(:bulk_import_entity, :finished, bulk_import: user_import_1) }

  let_it_be(:user_import_2) { create(:bulk_import, user: user) }
  let_it_be(:failed_entity_2) { create(:bulk_import_entity, :failed, bulk_import: user_import_2) }

  before do
    gitlab_sign_in(user)

    visit new_group_path

    click_link 'Import group'
  end

  it 'successfully displays import history' do
    click_link 'History'

    wait_for_requests

    expect(page).to have_content 'Group import history'
    expect(page.find('tbody')).to have_css('tr', count: 2)
  end
end
