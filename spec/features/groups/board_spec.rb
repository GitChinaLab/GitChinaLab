# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Boards' do
  include DragTo
  include MobileHelpers
  include BoardHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  context 'Creates an issue', :js do
    let_it_be(:project) { create(:project_empty_repo, group: group) }

    before do
      group.add_maintainer(user)

      sign_in(user)

      visit group_boards_path(group)
    end

    it 'adds an issue to the backlog' do
      page.within(find('.board', match: :first)) do
        issue_title = 'New Issue'
        click_button 'New issue'

        wait_for_requests

        expect(find('.board-new-issue-form')).to be_visible

        fill_in 'issue_title', with: issue_title

        page.within("[data-testid='project-select-dropdown']") do
          find('button.gl-dropdown-toggle').click

          find('.gl-new-dropdown-item button').click
        end

        click_button 'Create issue'

        expect(page).to have_content(issue_title)
      end
    end
  end

  context "when user is a Reporter in one of the group's projects", :js do
    let_it_be(:board) { create(:board, group: group) }

    let_it_be(:backlog_list) { create(:backlog_list, board: board) }
    let_it_be(:group_label1) { create(:group_label, title: "bug", group: group) }
    let_it_be(:group_label2) { create(:group_label, title: "dev", group: group) }
    let_it_be(:list1) { create(:list, board: board, label: group_label1, position: 0) }
    let_it_be(:list2) { create(:list, board: board, label: group_label2, position: 1) }

    let_it_be(:project1) { create(:project_empty_repo, :private, group: group) }
    let_it_be(:project2) { create(:project_empty_repo, :private, group: group) }
    let_it_be(:issue1) { create(:issue, title: 'issue1', project: project1, labels: [group_label2]) }
    let_it_be(:issue2) { create(:issue, title: 'issue2', project: project2) }

    before do
      project1.add_guest(user)
      project2.add_reporter(user)

      sign_in(user)

      inspect_requests(inject_headers: { 'X-GITLAB-DISABLE-SQL-QUERY-LIMIT' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/323426' }) do
        visit group_boards_path(group)
      end
    end

    it 'allows user to move issue of project where they are a Reporter' do
      expect(find('.board:nth-child(1)')).to have_content(issue2.title)

      drag(list_from_index: 0, from_index: 0, list_to_index: 1)

      expect(find('.board:nth-child(2)')).to have_content(issue2.title)
      expect(issue2.reload.labels).to contain_exactly(group_label1)
    end

    it 'does not allow user to move issue of project where they are a Guest' do
      expect(find('.board:nth-child(3)')).to have_content(issue1.title)

      drag(list_from_index: 2, from_index: 0, list_to_index: 1)

      expect(find('.board:nth-child(3)')).to have_content(issue1.title)
      expect(issue1.reload.labels).to contain_exactly(group_label2)
      expect(issue2.reload.labels).to eq([])
    end

    it 'does not allow user to re-position lists' do
      drag(list_from_index: 1, list_to_index: 2, selector: '.board-header')

      expect(find('.board:nth-child(2) [data-testid="board-list-header"]')).to have_content(group_label1.title)
      expect(find('.board:nth-child(3) [data-testid="board-list-header"]')).to have_content(group_label2.title)
      expect(list1.reload.position).to eq(0)
      expect(list2.reload.position).to eq(1)
    end
  end
end
