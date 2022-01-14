# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jobs/SAST-IaC.latest.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Jobs/SAST-IaC.latest') }

  describe 'the created pipeline' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.owner }

    let(:default_branch) { 'main' }
    let(:pipeline_ref) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_next_instance_of(Ci::BuildScheduleWorker) do |instance|
        allow(instance).to receive(:perform).and_return(true)
      end
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'on feature branch' do
      let(:pipeline_ref) { 'feature' }

      it 'creates the kics-iac-sast job' do
        expect(build_names).to contain_exactly('kics-iac-sast')
      end
    end

    context 'on merge request' do
      let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
      let(:merge_request) { create(:merge_request, :simple, source_project: project) }
      let(:pipeline) { service.execute(merge_request).payload }

      it 'has no jobs' do
        expect(pipeline).to be_merge_request_event
        expect(build_names).to be_empty
      end
    end

    context 'SAST_DISABLED is set' do
      before do
        create(:ci_variable, key: 'SAST_DISABLED', value: 'true', project: project)
      end

      context 'on default branch' do
        it 'has no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end

      context 'on feature branch' do
        let(:pipeline_ref) { 'feature' }

        it 'has no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end
    end
  end
end
