# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::NugetGroupPackages do
  include_context 'nuget api setup'

  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:subgroup) { create(:group, parent: group) }
  let_it_be_with_reload(:project) { create(:project, namespace: subgroup) }
  let_it_be(:deploy_token) { create(:deploy_token, :group, read_package_registry: true, write_package_registry: true) }
  let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token, group: group) }

  let(:target_type) { 'groups' }

  shared_examples 'handling all endpoints' do
    describe 'GET /api/v4/groups/:id/-/packages/nuget' do
      it_behaves_like 'handling nuget service requests', anonymous_requests_example_name: 'rejects nuget packages access', anonymous_requests_status: :unauthorized do
        let(:url) { "/groups/#{target.id}/-/packages/nuget/index.json" }
      end
    end

    describe 'GET /api/v4/groups/:id/-/packages/nuget/metadata/*package_name/index' do
      it_behaves_like 'handling nuget metadata requests with package name', anonymous_requests_example_name: 'rejects nuget packages access', anonymous_requests_status: :unauthorized do
        let(:url) { "/groups/#{target.id}/-/packages/nuget/metadata/#{package_name}/index.json" }
      end
    end

    describe 'GET /api/v4/groups/:id/-/packages/nuget/metadata/*package_name/*package_version' do
      it_behaves_like 'handling nuget metadata requests with package name and package version', anonymous_requests_example_name: 'rejects nuget packages access', anonymous_requests_status: :unauthorized do
        let(:url) { "/groups/#{target.id}/-/packages/nuget/metadata/#{package_name}/#{package.version}.json" }
      end
    end

    describe 'GET /api/v4/groups/:id/-/packages/nuget/query' do
      it_behaves_like 'handling nuget search requests', anonymous_requests_example_name: 'rejects nuget packages access', anonymous_requests_status: :unauthorized do
        let(:url) { "/groups/#{target.id}/-/packages/nuget/query?#{query_parameters.to_query}" }
      end
    end
  end

  context 'with a subgroup' do
    # Bug: deploy tokens at parent group will not see the subgroup.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/285495
    let_it_be(:group_deploy_token) { create(:group_deploy_token, deploy_token: deploy_token, group: subgroup) }

    let(:target) { subgroup }
    let(:snowplow_gitlab_standard_context) { { namespace: subgroup } }

    it_behaves_like 'handling all endpoints'

    def update_visibility_to(visibility)
      project.update!(visibility_level: visibility)
      subgroup.update!(visibility_level: visibility)
    end
  end

  context 'a group' do
    let(:target) { group }
    let(:snowplow_gitlab_standard_context) { { namespace: group } }

    it_behaves_like 'handling all endpoints'

    context 'with dummy packages and anonymous request' do
      let_it_be(:package_name) { 'Dummy.Package' }
      let_it_be(:packages) { create_list(:nuget_package, 5, :with_metadatum, name: package_name, project: project) }
      let_it_be(:tags) { packages.each { |pkg| create(:packages_tag, package: pkg, name: 'test') } }

      let(:search_term) { 'umm' }
      let(:take) { 26 }
      let(:skip) { 0 }
      let(:include_prereleases) { true }
      let(:query_parameters) { { q: search_term, take: take, skip: skip, prerelease: include_prereleases }.compact }

      subject { get api(url), headers: {}}

      shared_examples 'handling mixed visibilities' do
        where(:group_visibility, :subgroup_visibility, :expected_status) do
          'PUBLIC'   | 'PUBLIC'   | :unauthorized
          'PUBLIC'   | 'INTERNAL' | :unauthorized
          'PUBLIC'   | 'PRIVATE'  | :unauthorized
          'INTERNAL' | 'INTERNAL' | :unauthorized
          'INTERNAL' | 'PRIVATE'  | :unauthorized
          'PRIVATE'  | 'PRIVATE'  | :unauthorized
        end

        with_them do
          before do
            project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(subgroup_visibility, false))
            subgroup.update!(visibility_level: Gitlab::VisibilityLevel.const_get(subgroup_visibility, false))
            group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_visibility, false))
          end

          it_behaves_like 'returning response status', params[:expected_status]
        end
      end

      describe 'GET /api/v4/groups/:id/-/packages/nuget/metadata/*package_name/index' do
        it_behaves_like 'handling mixed visibilities' do
          let(:url) { "/groups/#{target.id}/-/packages/nuget/metadata/#{package_name}/index.json" }
        end
      end

      describe 'GET /api/v4/groups/:id/-/packages/nuget/metadata/*package_name/*package_version' do
        it_behaves_like 'handling mixed visibilities' do
          let(:url) { "/groups/#{target.id}/-/packages/nuget/metadata/#{package_name}/#{packages.first.version}.json" }
        end
      end

      describe 'GET /api/v4/groups/:id/-/packages/nuget/query' do
        it_behaves_like 'handling mixed visibilities' do
          let(:url) { "/groups/#{target.id}/-/packages/nuget/query?#{query_parameters.to_query}" }
        end
      end
    end

    context 'with a reporter of subgroup' do
      let_it_be(:package_name) { 'Dummy.Package' }
      let_it_be(:package) { create(:nuget_package, :with_metadatum, name: package_name, project: project) }

      let(:headers) { basic_auth_header(user.username, personal_access_token.token) }

      subject { get api(url), headers: headers }

      before do
        subgroup.add_reporter(user)
        project.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        subgroup.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
        group.update_column(:visibility_level, Gitlab::VisibilityLevel.level_value('private'))
      end

      describe 'GET /api/v4/groups/:id/-/packages/nuget/metadata/*package_name/index' do
        let(:url) { "/groups/#{group.id}/-/packages/nuget/metadata/#{package_name}/index.json" }

        it_behaves_like 'returning response status', :forbidden
      end

      describe 'GET /api/v4/groups/:id/-/packages/nuget/metadata/*package_name/*package_version' do
        let(:url) { "/groups/#{group.id}/-/packages/nuget/metadata/#{package_name}/#{package.version}.json" }

        it_behaves_like 'returning response status', :forbidden
      end

      describe 'GET /api/v4/groups/:id/-/packages/nuget/query' do
        let(:search_term) { 'uMmy' }
        let(:take) { 26 }
        let(:skip) { 0 }
        let(:include_prereleases) { false }
        let(:query_parameters) { { q: search_term, take: take, skip: skip, prerelease: include_prereleases }.compact }
        let(:url) { "/groups/#{group.id}/-/packages/nuget/query?#{query_parameters.to_query}" }

        it_behaves_like 'returning response status', :forbidden
      end
    end

    def update_visibility_to(visibility)
      project.update!(visibility_level: visibility)
      subgroup.update!(visibility_level: visibility)
      group.update!(visibility_level: visibility)
    end
  end
end
