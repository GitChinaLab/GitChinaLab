# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Issues RSS' do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let_it_be(:path) { project_issues_path(project) }
  let_it_be(:issue) { create(:issue, project: project, assignees: [user]) }

  before_all do
    group.add_developer(user)
  end

  context 'when signed in' do
    let_it_be(:user) { create(:user) }

    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
      visit path
    end

    it_behaves_like "it has an RSS button with current_user's feed token"
    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without a feed token"
    it_behaves_like "an autodiscoverable RSS feed without a feed token"
  end

  describe 'feeds' do
    it_behaves_like 'updates atom feed link', :project do
      let(:path) { project_issues_path(project, assignee_id: user.id) }
    end

    it_behaves_like 'updates atom feed link', :group do
      let(:path) { issues_group_path(group, assignee_id: user.id) }
    end
  end
end
