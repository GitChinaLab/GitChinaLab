# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :packages, :object_storage do
    describe 'Maven Repository with Gradle' do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include_context 'packages registry qa scenario'

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven_gradle-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven_gradle' }

      let(:package_gitlab_ci_file) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                deploy:
                  image: gradle:6.5-jdk11
                  script:
                  - 'gradle publish'
                  only:
                  - "#{package_project.default_branch}"
                  tags:
                  - "runner-for-#{package_project.group.name}"
              YAML
        }
      end

      let(:package_build_gradle_file) do
        {
          file_path: 'build.gradle',
          content:
              <<~EOF
                plugins {
                    id 'java'
                    id 'maven-publish'
                }

                publishing {
                    publications {
                        library(MavenPublication) {
                            groupId '#{group_id}'
                            artifactId '#{artifact_id}'
                            version '#{package_version}'
                            from components.java
                        }
                    }
                    repositories {
                        maven {
                            url "#{gitlab_address_with_port}/api/v4/projects/#{package_project.id}/packages/maven"
                            credentials(HttpHeaderCredentials) {
                                name = "Private-Token"
                                value = "#{personal_access_token}"
                            }
                            authentication {
                                header(HttpHeaderAuthentication)
                            }
                        }
                    }
                }
              EOF
        }
      end

      let(:client_gitlab_ci_file) do
        {
          file_path: '.gitlab-ci.yml',
          content:
              <<~YAML
                build:
                  image: gradle:6.5-jdk11
                  script:
                  - 'gradle build'
                  only:
                  - "#{client_project.default_branch}"
                  tags:
                  - "runner-for-#{client_project.group.name}"
              YAML
        }
      end

      where(:authentication_token_type, :maven_header_name) do
        :personal_access_token | 'Private-Token'
        :ci_job_token          | 'Job-Token'
        :project_deploy_token  | 'Deploy-Token'
      end

      with_them do
        let(:token) do
          case authentication_token_type
          when :personal_access_token
            "\"#{personal_access_token}\""
          when :ci_job_token
            'System.getenv("CI_JOB_TOKEN")'
          when :project_deploy_token
            "\"#{project_deploy_token.token}\""
          end
        end

        let(:client_build_gradle_file) do
          {
            file_path: 'build.gradle',
            content:
                <<~EOF
                  plugins {
                      id 'java'
                      id 'application'
                  }

                  repositories {
                      jcenter()
                      maven {
                          url "#{gitlab_address_with_port}/api/v4/projects/#{package_project.id}/packages/maven"
                          name "GitLab"
                          credentials(HttpHeaderCredentials) {
                              name = '#{maven_header_name}'
                              value = #{token}
                          }
                          authentication {
                              header(HttpHeaderAuthentication)
                          }
                      }
                  }

                  dependencies {
                      implementation group: '#{group_id}', name: '#{artifact_id}', version: '#{package_version}'
                      testImplementation 'junit:junit:4.12'
                  }

                  application {
                    mainClassName = 'gradle_maven_app.App'
                  }
                EOF
          }
        end

        it "pushes and pulls a maven package via gradle using #{params[:authentication_token_type]}" do
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = package_project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files([package_gitlab_ci_file, package_build_gradle_file])
            end
          end

          package_project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('deploy')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          Page::Project::Menu.perform(&:click_packages_link)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package_name)

            index.click_package(package_name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(package_name, package_version)
          end

          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = client_project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files([client_gitlab_ci_file, client_build_gradle_file])
            end
          end

          client_project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('build')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end
        end
      end
    end
  end
end
