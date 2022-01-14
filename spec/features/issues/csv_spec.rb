# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues csv', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let(:idea_label) { create(:label, project: project, title: 'Idea') }
  let(:feature_label) { create(:label, project: project, title: 'Feature', priority: 10) }
  let!(:issue) { create(:issue, project: project, author: user) }

  before do
    sign_in(user)
  end

  def request_csv(params = {})
    visit project_issues_path(project, params)
    click_button 'Export as CSV'
    click_on 'Export issues'
  end

  def attachment
    ActionMailer::Base.deliveries.last.attachments.first
  end

  def csv
    CSV.parse(attachment.decode_body, headers: true)
  end

  it 'triggers an email export' do
    expect(IssuableExportCsvWorker).to receive(:perform_async).with(:issue, user.id, project.id, hash_including("project_id" => project.id))

    request_csv
  end

  it "doesn't send request params to ExportCsvWorker" do
    expect(IssuableExportCsvWorker).to receive(:perform_async).with(:issue, anything, anything, hash_excluding("controller" => anything, "action" => anything))

    request_csv
  end

  it 'displays flash message' do
    request_csv

    expect(page).to have_content 'CSV export has started'
    expect(page).to have_content "emailed to #{user.notification_email_or_default}"
  end

  it 'includes a csv attachment', :sidekiq_inline do
    request_csv

    expect(attachment.content_type).to include('text/csv')
  end

  it 'ignores pagination', :sidekiq_inline do
    create_list(:issue, 30, project: project, author: user)

    request_csv

    expect(csv.count).to eq 31
  end

  it 'uses filters from issue index', :sidekiq_inline do
    request_csv(state: :closed)

    expect(csv.count).to eq 0
  end

  it 'ignores sorting from issue index', :sidekiq_inline do
    issue2 = create(:labeled_issue, project: project, author: user, labels: [feature_label])

    request_csv(sort: :label_priority)

    expected = [issue.iid.to_s, issue2.iid.to_s]
    expect(csv.map { |row| row['Issue ID'] }).to eq expected
  end

  it 'uses array filters, such as label_name', :sidekiq_inline do
    issue.update!(labels: [idea_label])

    request_csv("label_name[]" => 'Bug')

    expect(csv.count).to eq 0
  end
end
