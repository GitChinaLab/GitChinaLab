# frozen_string_literal: true

module QA
  RSpec.describe 'Package Registry', :orchestrated, :packages, :reliable, :object_storage do
    describe 'npm project level endpoint' do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures

      let!(:registry_scope) { Runtime::Namespace.sandbox_name }
      let!(:personal_access_token) do
        unless Page::Main::Menu.perform(&:signed_in?)
          Flow::Login.sign_in
        end

        Resource::PersonalAccessToken.fabricate!.token
      end

      let(:project_deploy_token) do
        Resource::ProjectDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'npm-deploy-token'
          deploy_token.project = project
          deploy_token.scopes = %w[
            read_repository
            read_package_registry
            write_package_registry
          ]
        end
      end

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
      let(:gitlab_address_with_port) { "#{uri.scheme}://#{uri.host}:#{uri.port}" }
      let(:gitlab_host_with_port) { "#{uri.host}:#{uri.port}" }

      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'npm-project-level'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.name}"]
          runner.executor = :docker
          runner.project = project
        end
      end

      let(:gitlab_ci_yaml) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
              image: node:latest

              stages:
                - deploy
                - install
              
              deploy:
                stage: deploy
                script:
                  - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=#{auth_token}">.npmrc
                  - npm publish
                only:
                  - "#{project.default_branch}"
                tags:
                  - "runner-for-#{project.name}"
              install:
                stage: install
                script:
                  - "npm config set @#{registry_scope}:registry #{gitlab_address_with_port}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/"
                  - "npm install #{package.name}"
                cache:
                  key: ${CI_BUILD_REF_NAME}
                  paths:
                    - node_modules/
                artifacts:
                  paths:
                    - node_modules/
                only:
                  - "#{project.default_branch}"
                tags:
                  - "runner-for-#{project.name}"
              YAML
        }
      end

      let(:package_json) do
        {
          file_path: 'package.json',
          content: <<~JSON
            {
              "name": "#{package.name}",
              "version": "1.0.0",
              "description": "Example package for GitLab npm registry",
              "publishConfig": {
                "@#{registry_scope}:registry": "#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/npm/"
              }
            }
          JSON
      }
      end

      let(:package) do
        Resource::Package.init do |package|
          package.name = "@#{registry_scope}/mypackage-#{SecureRandom.hex(8)}"
          package.project = project
        end
      end

      after do
        package.remove_via_api!
        runner.remove_via_api!
        project.remove_via_api!
      end

      where(:authentication_token_type, :token_name) do
        :personal_access_token | 'Personal Access Token'
        :ci_job_token          | 'CI Job Token'
        :project_deploy_token  | 'Deploy Token'
      end

      with_them do
        let(:auth_token) do
          case authentication_token_type
          when :personal_access_token
            "\"#{personal_access_token}\""
          when :ci_job_token
            '${CI_JOB_TOKEN}'
          when :project_deploy_token
            "\"#{project_deploy_token.token}\""
          end
        end

        it "push and pull a npm package via CI using a #{params[:token_name]}" do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files([
                              gitlab_ci_yaml,
                              package_json
                            ])
          end

          project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('install')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
            job.click_browse_button
          end

          Page::Project::Artifact::Show.perform do |artifacts|
            artifacts.go_to_directory('node_modules')
            artifacts.go_to_directory("@#{registry_scope}")
            expect(artifacts).to have_content('mypackage')
          end

          project.visit!
          Page::Project::Menu.perform(&:click_packages_link)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package.name)

            index.click_package(package.name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(package.name, "1.0.0")

            show.click_delete
          end

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_content("Package deleted successfully")
            expect(index).not_to have_package(package.name)
          end
        end
      end
    end
  end
end
