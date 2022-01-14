# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, only: { pipeline: :main } do
    describe 'Self-managed Container Registry' do
      using RSpec::Parameterized::TableSyntax

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-registry'
          project.template_name = 'express'
          project.visibility = :private
        end
      end

      let(:project_deploy_token) do
        Resource::ProjectDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'registry-deploy-token'
          deploy_token.project = project
          deploy_token.scopes = %w[
            read_repository
            read_package_registry
            write_package_registry
            read_registry
            write_registry
          ]
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

      let(:personal_access_token) { Runtime::Env.personal_access_token }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      after do
        runner.remove_via_api!
        project.remove_via_api!
      end

      context "when tls is disabled" do
        where(:authentication_token_type, :token_name) do
          :personal_access_token | 'Personal Access Token'
          :project_deploy_token  | 'Deploy Token'
          :ci_job_token          | 'Job Token'
        end

        with_them do
          let(:auth_token) do
            case authentication_token_type
            when :personal_access_token
              "\"#{personal_access_token}\""
            when :project_deploy_token
              "\"#{project_deploy_token.token}\""
            when :ci_job_token
              '$CI_JOB_TOKEN'
            end
          end

          let(:auth_user) do
            case authentication_token_type
            when :personal_access_token
              "$CI_REGISTRY_USER"
            when :project_deploy_token
              "\"#{project_deploy_token.username}\""
            when :ci_job_token
              'gitlab-ci-token'
            end
          end

          where(:docker_client_version) do
            %w[docker:18.09.9 docker:19.03.12 docker:20.10]
          end

          with_them do
            it "pushes image and deletes tag", :registry do
              Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
                Resource::Repository::Commit.fabricate_via_api! do |commit|
                  commit.project = project
                  commit.commit_message = 'Add .gitlab-ci.yml'
                  commit.add_files([{
                                      file_path: '.gitlab-ci.yml',
                                      content:
                                          <<~YAML
                                            build:
                                              image: "#{docker_client_version}"
                                              stage: build
                                              services:
                                              - name: "#{docker_client_version}-dind"
                                                command: ["--insecure-registry=gitlab.test:5050"]                                
                                              variables:
                                                IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
                                              script:
                                                - docker login -u #{auth_user} -p #{auth_token} gitlab.test:5050
                                                - docker build -t $IMAGE_TAG .
                                                - docker push $IMAGE_TAG
                                              tags:
                                                - "runner-for-#{project.name}"
                                          YAML
                                  }])
                end
              end

              Flow::Pipeline.visit_latest_pipeline

              Page::Project::Pipeline::Show.perform do |pipeline|
                pipeline.click_job('build')
              end

              Page::Project::Job::Show.perform do |job|
                expect(job).to be_successful(timeout: 800)
              end

              Page::Project::Menu.perform(&:go_to_container_registry)

              Page::Project::Registry::Show.perform do |registry|
                expect(registry).to have_registry_repository(project.path_with_namespace)

                registry.click_on_image(project.path_with_namespace)
                expect(registry).to have_tag('master')
              end
            end
          end
        end
      end

      context "when tls is enabled" do
        it "pushes image and deletes tag", :registry_tls, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347591' do
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files([{
                                  file_path: '.gitlab-ci.yml',
                                  content:
                                      <<~YAML
                                        build:
                                          image: docker:19.03.12
                                          stage: build
                                          services:
                                          - name: docker:19.03.12-dind
                                            command:
                                            - /bin/sh
                                            - -c
                                            - |
                                              apk add --no-cache openssl
                                              true | openssl s_client -showcerts -connect gitlab.test:5050 > /usr/local/share/ca-certificates/gitlab.test.crt
                                              update-ca-certificates
                                              dockerd-entrypoint.sh || exit                                
                                          variables:
                                            IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
                                          script:
                                            - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD gitlab.test:5050
                                            - docker build -t $IMAGE_TAG .
                                            - docker push $IMAGE_TAG
                                          tags:
                                            - "runner-for-#{project.name}"
                                      YAML
                              }])
            end
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('build')
          end

          Support::Retrier.retry_until(max_duration: 800, sleep_interval: 10) do
            project.pipelines.last[:status] == 'success'
          end

          Page::Project::Menu.perform(&:go_to_container_registry)

          Page::Project::Registry::Show.perform do |registry|
            expect(registry).to have_registry_repository(project.path_with_namespace)

            registry.click_on_image(project.path_with_namespace)
            expect(registry).to have_tag('master')

            registry.click_delete
            expect(registry).not_to have_tag('master')
          end
        end
      end
    end
  end
end
