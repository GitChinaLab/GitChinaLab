# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ContributionsCalendar do
  let(:contributor) { create(:user) }
  let(:user) { create(:user) }
  let(:travel_time) { nil }

  let(:private_project) do
    create(:project, :private) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let(:public_project) do
    create(:project, :public, :repository) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let(:feature_project) do
    create(:project, :public, :issues_private) do |project|
      create(:project_member, user: contributor, project: project).project
    end
  end

  let(:today) { Time.now.utc.to_date }
  let(:yesterday) { today - 1.day }
  let(:tomorrow)  { today + 1.day }
  let(:last_week) { today - 7.days }
  let(:last_year) { today - 1.year }

  before do
    travel_to travel_time || Time.now.utc.end_of_day
  end

  after do
    travel_back
  end

  def calendar(current_user = nil)
    described_class.new(contributor, current_user)
  end

  def create_event(project, day, hour = 0, action = :created, target_symbol = :issue)
    @targets ||= {}
    @targets[project] ||= create(target_symbol, project: project, author: contributor)

    Event.create!(
      project: project,
      action: action,
      target_type: @targets[project].class.name,
      target_id: @targets[project].id,
      author: contributor,
      created_at: DateTime.new(day.year, day.month, day.day, hour)
    )
  end

  describe '#activity_dates' do
    it "returns a hash of date => count" do
      create_event(public_project, last_week)
      create_event(public_project, last_week)
      create_event(public_project, today)

      expect(calendar.activity_dates).to eq(last_week => 2, today => 1)
    end

    context "when the user has opted-in for private contributions" do
      before do
        contributor.update_column(:include_private_contributions, true)
      end

      it "shows private and public events to all users" do
        create_event(private_project, today)
        create_event(public_project, today)

        expect(calendar.activity_dates[today]).to eq(2)
        expect(calendar(user).activity_dates[today]).to eq(2)
        expect(calendar(contributor).activity_dates[today]).to eq(2)
      end

      # tests for bug https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74826
      it "still counts correct with feature access levels set to private" do
        create_event(private_project, today)

        private_project.project_feature.update_attribute(:issues_access_level, ProjectFeature::PRIVATE)
        private_project.project_feature.update_attribute(:repository_access_level, ProjectFeature::PRIVATE)
        private_project.project_feature.update_attribute(:merge_requests_access_level, ProjectFeature::PRIVATE)

        expect(calendar.activity_dates[today]).to eq(1)
        expect(calendar(user).activity_dates[today]).to eq(1)
        expect(calendar(contributor).activity_dates[today]).to eq(1)
      end

      it "does not fail if there are no contributed projects" do
        expect(calendar.activity_dates[today]).to eq(nil)
      end
    end

    it "counts the diff notes on merge request" do
      create_event(public_project, today, 0, :commented, :diff_note_on_merge_request)

      expect(calendar(contributor).activity_dates[today]).to eq(1)
    end

    it "counts the discussions on merge requests and issues" do
      create_event(public_project, today, 0, :commented, :discussion_note_on_merge_request)
      create_event(public_project, today, 2, :commented, :discussion_note_on_issue)

      expect(calendar(contributor).activity_dates[today]).to eq(2)
    end

    context "when events fall under different dates depending on the system time zone" do
      before do
        create_event(public_project, today, 1)
        create_event(public_project, today, 4)
        create_event(public_project, today, 10)
        create_event(public_project, today, 16)
        create_event(public_project, today, 23)
      end

      it "renders correct event counts within the UTC timezone" do
        Time.use_zone('UTC') do
          expect(calendar.activity_dates).to eq(today => 5)
        end
      end

      it "renders correct event counts within the Sydney timezone" do
        Time.use_zone('Sydney') do
          expect(calendar.activity_dates).to eq(today => 3, tomorrow => 2)
        end
      end

      it "renders correct event counts within the US Central timezone" do
        Time.use_zone('Central Time (US & Canada)') do
          expect(calendar.activity_dates).to eq(yesterday => 2, today => 3)
        end
      end
    end

    context "when events fall under different dates depending on the contributor's time zone" do
      before do
        create_event(public_project, today, 1)
        create_event(public_project, today, 4)
        create_event(public_project, today, 10)
        create_event(public_project, today, 16)
        create_event(public_project, today, 23)
        create_event(public_project, tomorrow, 1)
      end

      it "renders correct event counts within the UTC timezone" do
        Time.use_zone('UTC') do
          contributor.timezone = 'UTC'
          expect(calendar.activity_dates).to eq(today => 5)
        end
      end

      it "renders correct event counts within the Sydney timezone" do
        Time.use_zone('UTC') do
          contributor.timezone = 'Sydney'
          expect(calendar.activity_dates).to eq(today => 3, tomorrow => 3)
        end
      end

      it "renders correct event counts within the US Central timezone" do
        Time.use_zone('UTC') do
          contributor.timezone = 'Central Time (US & Canada)'
          expect(calendar.activity_dates).to eq(yesterday => 2, today => 4)
        end
      end
    end
  end

  describe '#events_by_date' do
    it "returns all events for a given date" do
      e1 = create_event(public_project, today)
      e2 = create_event(public_project, today)
      create_event(public_project, last_week)

      expect(calendar.events_by_date(today)).to contain_exactly(e1, e2)
    end

    it "only shows private events to authorized users" do
      e1 = create_event(public_project, today)
      e2 = create_event(private_project, today)
      e3 = create_event(feature_project, today)
      create_event(public_project, last_week)

      expect(calendar.events_by_date(today)).to contain_exactly(e1, e3)
      expect(calendar(contributor).events_by_date(today)).to contain_exactly(e1, e2, e3)
    end

    it "includes diff notes on merge request" do
      e1 = create_event(public_project, today, 0, :commented, :diff_note_on_merge_request)

      expect(calendar.events_by_date(today)).to contain_exactly(e1)
    end

    context 'when the user cannot read cross project' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
      end

      it 'does not return any events' do
        create_event(public_project, today)

        expect(calendar(user).events_by_date(today)).to be_empty
      end
    end
  end

  describe '#starting_year' do
    let(:travel_time) { Time.find_zone('UTC').local(2020, 12, 31, 19, 0, 0) }

    context "when the contributor's timezone is not set" do
      it "is the start of last year in the system timezone" do
        expect(calendar.starting_year).to eq(2019)
      end
    end

    context "when the contributor's timezone is set to Sydney" do
      let(:contributor) { create(:user, { timezone: 'Sydney' }) }

      it "is the start of last year in Sydney" do
        expect(calendar.starting_year).to eq(2020)
      end
    end
  end

  describe '#starting_month' do
    let(:travel_time) { Time.find_zone('UTC').local(2020, 12, 31, 19, 0, 0) }

    context "when the contributor's timezone is not set" do
      it "is the start of this month in the system timezone" do
        expect(calendar.starting_month).to eq(12)
      end
    end

    context "when the contributor's timezone is set to Sydney" do
      let(:contributor) { create(:user, { timezone: 'Sydney' }) }

      it "is the start of this month in Sydney" do
        expect(calendar.starting_month).to eq(1)
      end
    end
  end
end
