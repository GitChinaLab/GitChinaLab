# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequestsController do
  context 'token authentication' do
    context 'when public project' do
      let_it_be(:public_project) { create(:project, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: true do
        let(:url) { project_merge_requests_url(public_project, format: :atom) }
      end
    end

    context 'when private project' do
      let_it_be(:private_project) { create(:project, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'index atom', public_resource: false, ignore_metrics: true do
        let(:url) { project_merge_requests_url(private_project, format: :atom) }

        before do
          private_project.add_maintainer(user)
        end
      end
    end
  end
end
