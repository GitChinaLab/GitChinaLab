# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Timelog do
  subject { create(:timelog) }

  let_it_be(:issue) { create(:issue) }
  let_it_be(:merge_request) { create(:merge_request) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:issue).touch(true) }
  it { is_expected.to belong_to(:merge_request).touch(true) }

  it { is_expected.to be_valid }

  it { is_expected.to validate_presence_of(:time_spent) }
  it { is_expected.to validate_presence_of(:user) }

  it { is_expected.to validate_length_of(:summary).is_at_most(255) }

  it { expect(subject.project_id).not_to be_nil }

  describe 'validation' do
    it 'is invalid if issue_id and merge_request_id are missing' do
      subject.attributes = { issue: nil, merge_request: nil }

      expect(subject).to be_invalid
    end

    it 'is invalid if issue_id and merge_request_id are set' do
      subject.attributes = { issue: issue, merge_request: merge_request }

      expect(subject).to be_invalid
    end

    it 'is valid if only issue_id is set' do
      subject.attributes = { issue: issue, merge_request: nil }

      expect(subject).to be_valid
    end

    it 'is valid if only merge_request_id is set' do
      subject.attributes = { merge_request: merge_request, issue: nil }

      expect(subject).to be_valid
    end

    describe 'when importing' do
      it 'is valid if issue_id and merge_request_id are missing' do
        subject.attributes = { issue: nil, merge_request: nil, importing: true }

        expect(subject).to be_valid
      end
    end
  end

  describe 'scopes' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_project) { create(:project, :empty_repo, group: group) }
    let_it_be(:group_issue) { create(:issue, project: group_project) }
    let_it_be(:group_merge_request) { create(:merge_request, source_project: group_project) }

    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:subgroup_project) { create(:project, :empty_repo, group: subgroup) }
    let_it_be(:subgroup_issue) { create(:issue, project: subgroup_project) }
    let_it_be(:subgroup_merge_request) { create(:merge_request, source_project: subgroup_project) }

    let_it_be(:short_time_ago) { 5.days.ago }
    let_it_be(:medium_time_ago) { 15.days.ago }
    let_it_be(:long_time_ago) { 65.days.ago }

    let_it_be(:user) { create(:user) }
    let_it_be(:timelog) { create(:issue_timelog, spent_at: long_time_ago, user: user) }
    let_it_be(:timelog1) { create(:issue_timelog, spent_at: medium_time_ago, issue: group_issue, user: user) }
    let_it_be(:timelog2) { create(:issue_timelog, spent_at: short_time_ago, issue: subgroup_issue) }
    let_it_be(:timelog3) { create(:merge_request_timelog, spent_at: long_time_ago) }
    let_it_be(:timelog4) { create(:merge_request_timelog, spent_at: medium_time_ago, merge_request: group_merge_request) }
    let_it_be(:timelog5) { create(:merge_request_timelog, spent_at: short_time_ago, merge_request: subgroup_merge_request) }

    describe '.in_group' do
      it 'return timelogs created for group issues and merge requests' do
        expect(described_class.in_group(group)).to contain_exactly(timelog1, timelog2, timelog4, timelog5)
      end
    end

    describe '.for_user' do
      it 'return timelogs created by user' do
        expect(described_class.for_user(user)).to contain_exactly(timelog, timelog1)
      end
    end

    describe '.in_project' do
      it 'returns timelogs created for project issues and merge requests' do
        project = create(:project, :empty_repo)

        create(:issue_timelog)
        create(:merge_request_timelog)
        timelog1 = create(:issue_timelog, issue: create(:issue, project: project))
        timelog2 = create(:merge_request_timelog, merge_request: create(:merge_request, source_project: project))

        expect(described_class.in_project(project.id)).to contain_exactly(timelog1, timelog2)
      end
    end

    describe '.at_or_after' do
      it 'returns timelogs at the time limit' do
        timelogs = described_class.at_or_after(short_time_ago)

        expect(timelogs).to contain_exactly(timelog2, timelog5)
      end

      it 'returns timelogs after given time' do
        timelogs = described_class.at_or_after(just_before(short_time_ago))

        expect(timelogs).to contain_exactly(timelog2, timelog5)
      end
    end

    describe '.at_or_before' do
      it 'returns timelogs at the time limit' do
        timelogs = described_class.at_or_before(long_time_ago)

        expect(timelogs).to contain_exactly(timelog, timelog3)
      end

      it 'returns timelogs before given time' do
        timelogs = described_class.at_or_before(just_after(long_time_ago))

        expect(timelogs).to contain_exactly(timelog, timelog3)
      end
    end

    def just_before(time)
      time - 1.day
    end

    def just_after(time)
      time + 1.day
    end
  end

  describe 'hooks' do
    describe '.set_project' do
      it 'populates project with issuable project' do
        timelog = create(:issue_timelog, issue: issue)

        expect(timelog.project_id).to be(timelog.issue.project_id)
      end
    end
  end
end
