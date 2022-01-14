# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateTimelogsNullSpentAt, schema: 20211215090620 do
  let_it_be(:previous_time) { 10.days.ago }
  let_it_be(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let_it_be(:project) { table(:projects).create!(namespace_id: namespace.id) }
  let_it_be(:issue) { table(:issues).create!(project_id: project.id) }
  let_it_be(:merge_request) { table(:merge_requests).create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature') }
  let_it_be(:timelog1) { create_timelog!(issue_id: issue.id) }
  let_it_be(:timelog2) { create_timelog!(merge_request_id: merge_request.id) }
  let_it_be(:timelog3) { create_timelog!(issue_id: issue.id, spent_at: previous_time) }
  let_it_be(:timelog4) { create_timelog!(merge_request_id: merge_request.id, spent_at: previous_time) }

  subject(:background_migration) { described_class.new }

  before_all do
    table(:timelogs).where.not(id: [timelog3.id, timelog4.id]).update_all(spent_at: nil)
  end

  describe '#perform' do
    it 'sets correct spent_at' do
      background_migration.perform(timelog1.id, timelog4.id)

      expect(timelog1.reload.spent_at).to be_like_time(timelog1.created_at)
      expect(timelog2.reload.spent_at).to be_like_time(timelog2.created_at)
      expect(timelog3.reload.spent_at).to be_like_time(previous_time)
      expect(timelog4.reload.spent_at).to be_like_time(previous_time)
      expect(timelog3.reload.spent_at).not_to be_like_time(timelog3.created_at)
      expect(timelog4.reload.spent_at).not_to be_like_time(timelog4.created_at)
    end
  end

  private

  def create_timelog!(**args)
    table(:timelogs).create!(**args, time_spent: 1)
  end
end
