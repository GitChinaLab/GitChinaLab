# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User browses a job', :js do
  let(:user) { create(:user) }
  let(:user_access_level) { :developer }
  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let!(:build) { create(:ci_build, :success, :trace_artifact, :coverage, pipeline: pipeline) }

  before do
    project.add_maintainer(user)
    project.enable_ci
    stub_feature_flags(bootstrap_confirmation_modals: false)

    sign_in(user)

    visit(project_job_path(project, build))
  end

  it 'erases the job log', :js do
    wait_for_requests

    expect(page).to have_content("Job #{build.name}")
    expect(page).to have_css('.job-log')

    # scroll to the top of the page first
    execute_script "window.scrollTo(0,0)"
    accept_confirm { find('[data-testid="job-log-erase-link"]').click }

    expect(page).to have_no_css('.artifacts')
    expect(build).not_to have_trace
    expect(build.artifacts_file.present?).to be_falsy
    expect(build.artifacts_metadata.present?).to be_falsy

    expect(page).to have_content('Job has been erased')
  end

  context 'with unarchived trace artifact' do
    let!(:build) { create(:ci_build, :success, :unarchived_trace_artifact, :coverage, pipeline: pipeline) }

    it 'shows no trace message', :js do
      wait_for_requests

      expect(page).to have_content('This job does not have a trace.')
    end
  end

  context 'with a failed job and live trace' do
    let!(:build) { create(:ci_build, :failed, :trace_live, pipeline: pipeline) }

    it 'displays the failure reason' do
      wait_for_all_requests
      within('.builds-container') do
        expect(page).to have_selector(
          ".build-job > a[title='test - failed - (unknown failure)']")
      end
    end

    context 'with unarchived trace artifact' do
      let!(:artifact) { create(:ci_job_artifact, :unarchived_trace_artifact, job: build) }

      it 'displays the failure reason from the live trace' do
        wait_for_all_requests
        within('.builds-container') do
          expect(page).to have_selector(
            ".build-job > a[title='test - failed - (unknown failure)']")
        end
      end
    end
  end

  context 'when a failed job has been retried' do
    let!(:build_retried) { create(:ci_build, :failed, :retried, :trace_artifact, pipeline: pipeline) }

    it 'displays the failure reason and retried label' do
      wait_for_all_requests
      within('.builds-container') do
        expect(page).to have_selector(
          ".build-job > a[title='test - failed - (unknown failure) (retried)']")
      end
    end
  end
end
