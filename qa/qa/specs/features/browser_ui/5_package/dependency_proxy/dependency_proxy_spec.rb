# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :registry, only: { pipeline: :main } do
    describe 'Dependency Proxy' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'dependency-proxy-project'
          project.visibility = :private
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

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
      let(:gitlab_host_with_port) { "#{uri.host}:#{uri.port}" }
      let(:dependency_proxy_url) { "#{gitlab_host_with_port}/#{project.group.full_path}/dependency_proxy/containers" }
      let(:image_sha) { 'alpine@sha256:c3d45491770c51da4ef58318e3714da686bc7165338b7ab5ac758e75c7455efb' }

      before do
        Flow::Login.sign_in

        project.group.visit!

        Page::Group::Menu.perform(&:go_to_package_settings)

        Page::Group::Settings::PackageRegistries.perform do |index|
          expect(index).to have_dependency_proxy_enabled
        end
      end

      after do
        runner.remove_via_api!
      end

      where(:docker_client_version) do
        %w[docker:19.03.12 docker:20.10]
      end

      with_them do
        it "pulls an image using the dependency proxy" do
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files([{
                                  file_path: '.gitlab-ci.yml',
                                  content:
                                      <<~YAML
                                        dependency-proxy-pull-test:
                                          image: "#{docker_client_version}"
                                          services:
                                          - name: "#{docker_client_version}-dind"
                                            command: ["--insecure-registry=gitlab.test:80"]     
                                          before_script:
                                            - apk add curl jq grep
                                            - echo $CI_DEPENDENCY_PROXY_SERVER
                                            - docker login -u "$CI_DEPENDENCY_PROXY_USER" -p "$CI_DEPENDENCY_PROXY_PASSWORD" gitlab.test:80
                                          script:
                                            - docker pull #{dependency_proxy_url}/#{image_sha}
                                            - TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq --raw-output .token)
                                            - 'curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1'
                                            - docker pull #{dependency_proxy_url}/#{image_sha}
                                            - 'curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1'
                                          tags:
                                          - "runner-for-#{project.name}"
                                      YAML
                              }])
            end
          end

          project.visit!
          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('dependency-proxy-pull-test')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          project.group.visit!

          Page::Group::Menu.perform(&:go_to_dependency_proxy)

          Page::Group::DependencyProxy.perform do |index|
            expect(index).to have_blob_count("Contains 1 blobs of images")
          end
        end
      end
    end
  end
end
