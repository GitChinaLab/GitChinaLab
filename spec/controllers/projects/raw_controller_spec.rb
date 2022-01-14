# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RawController do
  include RepoHelpers

  let_it_be(:project) { create(:project, :public, :repository) }

  let(:inline) { nil }

  describe 'GET #show' do
    def get_show
      get(:show,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            id: filepath,
            inline: inline
          })
    end

    subject { get_show }

    shared_examples 'single Gitaly request' do
      it 'makes a single Gitaly request', :request_store, :clean_gitlab_redis_cache do
        # Warm up to populate repository cache
        get_show
        RequestStore.clear!

        expect { get_show }.to change { Gitlab::GitalyClient.get_request_count }.by(1)
      end
    end

    context 'regular filename' do
      let(:filepath) { 'master/CONTRIBUTING.md' }

      it 'delivers ASCII file' do
        allow(Gitlab::Workhorse).to receive(:send_git_blob).and_call_original

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')

        expect(Gitlab::Workhorse).to have_received(:send_git_blob) do |repository, blob|
          expected_blob = project.repository.blob_at('master', 'CONTRIBUTING.md')

          expect(repository).to eq(project.repository)
          expect(blob.id).to eq(expected_blob.id)
          expect(blob).to be_truncated
        end
      end

      it_behaves_like 'project cache control headers'
      it_behaves_like 'content disposition headers'
      include_examples 'single Gitaly request'
    end

    context 'image header' do
      let(:filepath) { 'master/files/images/6049019_460s.jpg' }

      it 'leaves image content disposition' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
      end

      it_behaves_like 'project cache control headers'
      it_behaves_like 'content disposition headers'
      include_examples 'single Gitaly request'
    end

    context 'with LFS files' do
      let(:filename) { 'lfs_object.iso' }
      let(:filepath) { "be93687/files/lfs/#{filename}" }

      it_behaves_like 'a controller that can serve LFS files'
      it_behaves_like 'project cache control headers'
      include_examples 'single Gitaly request'
    end

    context 'when the endpoint receives requests above the limit', :clean_gitlab_redis_rate_limiting do
      let(:file_path) { 'master/README.md' }

      before do
        stub_application_setting(raw_blob_request_limit: 5)
      end

      it 'prevents from accessing the raw file', :request_store do
        execute_raw_requests(requests: 5, project: project, file_path: file_path)

        expect { execute_raw_requests(requests: 1, project: project, file_path: file_path) }
          .to change { Gitlab::GitalyClient.get_request_count }.by(0)

        expect(response.body).to eq(_('You cannot access the raw file. Please wait a minute.'))
        expect(response).to have_gitlab_http_status(:too_many_requests)
      end

      it 'logs the event on auth.log', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/345889' do
        attributes = {
          message: 'Application_Rate_Limiter_Request',
          env: :raw_blob_request_limit,
          remote_ip: '0.0.0.0',
          request_method: 'GET',
          path: "/#{project.full_path}/-/raw/#{file_path}"
        }

        expect(Gitlab::AuthLogger).to receive(:error).with(attributes).once

        execute_raw_requests(requests: 6, project: project, file_path: file_path)
      end

      context 'when receiving an external storage request' do
        let(:token) { 'letmein' }

        before do
          stub_application_setting(
            static_objects_external_storage_url: 'https://cdn.gitlab.com',
            static_objects_external_storage_auth_token: token
          )
        end

        it 'does not prevent from accessing the raw file' do
          request.headers['X-Gitlab-External-Storage-Token'] = token
          execute_raw_requests(requests: 6, project: project, file_path: file_path)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the request uses a different version of a commit' do
        it 'prevents from accessing the raw file' do
          # 3 times with the normal sha
          commit_sha = project.repository.commit.sha
          file_path = "#{commit_sha}/README.md"

          execute_raw_requests(requests: 3, project: project, file_path: file_path)

          # 3 times with the modified version
          modified_sha = commit_sha.gsub(commit_sha[0..5], commit_sha[0..5].upcase)
          modified_path = "#{modified_sha}/README.md"

          execute_raw_requests(requests: 3, project: project, file_path: modified_path)

          expect(response.body).to eq(_('You cannot access the raw file. Please wait a minute.'))
          expect(response).to have_gitlab_http_status(:too_many_requests)
        end
      end

      context 'when the throttling has been disabled' do
        before do
          stub_application_setting(raw_blob_request_limit: 0)
        end

        it 'does not prevent from accessing the raw file' do
          execute_raw_requests(requests: 10, project: project, file_path: file_path)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with case-sensitive files' do
        it 'prevents from accessing the specific file' do
          create_file_in_repo(project, 'master', 'master', 'readme.md', 'Add readme.md')
          create_file_in_repo(project, 'master', 'master', 'README.md', 'Add README.md')

          commit_sha = project.repository.commit.sha
          file_path = "#{commit_sha}/readme.md"

          # Accessing downcase version of readme
          execute_raw_requests(requests: 6, project: project, file_path: file_path)

          expect(response.body).to eq(_('You cannot access the raw file. Please wait a minute.'))
          expect(response).to have_gitlab_http_status(:too_many_requests)

          # Accessing upcase version of readme
          file_path = "#{commit_sha}/README.md"

          execute_raw_requests(requests: 1, project: project, file_path: file_path)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'as a sessionless user' do
      let_it_be(:project) { create(:project, :private, :repository) }
      let_it_be(:user) { create(:user, static_object_token: 'very-secure-token') }
      let_it_be(:file_path) { 'master/README.md' }

      let(:token) { user.static_object_token }

      before do
        project.add_developer(user)
      end

      context 'when no token is provided' do
        it 'redirects to sign in page' do
          execute_raw_requests(requests: 1, project: project, file_path: file_path)

          expect(response).to have_gitlab_http_status(:found)
          expect(response.location).to end_with('/users/sign_in')
        end
      end

      context 'when a token param is present' do
        subject(:execute_raw_request_with_token_in_params) do
          execute_raw_requests(requests: 1, project: project, file_path: file_path, token: token)
        end

        context 'when token is correct' do
          it 'calls the action normally' do
            execute_raw_request_with_token_in_params

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'when user with expired password' do
            let_it_be(:user) { create(:user, password_expires_at: 2.minutes.ago) }

            it 'redirects to sign in page' do
              execute_raw_request_with_token_in_params

              expect(response).to have_gitlab_http_status(:found)
              expect(response.location).to end_with('/users/sign_in')
            end
          end

          context 'when password expiration is not applicable' do
            context 'when ldap user' do
              let_it_be(:user) { create(:omniauth_user, provider: 'ldap', password_expires_at: 2.minutes.ago) }

              it 'calls the action normally' do
                execute_raw_request_with_token_in_params

                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end
        end

        context 'when token is incorrect' do
          let(:token) { 'foobar' }

          it 'redirects to sign in page' do
            execute_raw_request_with_token_in_params

            expect(response).to have_gitlab_http_status(:found)
            expect(response.location).to end_with('/users/sign_in')
          end
        end
      end

      context 'when a token header is present' do
        subject(:execute_raw_request_with_token_in_headers) do
          request.headers['X-Gitlab-Static-Object-Token'] = token
          execute_raw_requests(requests: 1, project: project, file_path: file_path)
        end

        context 'when token is correct' do
          it 'calls the action normally' do
            execute_raw_request_with_token_in_headers

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'when user with expired password' do
            let_it_be(:user) { create(:user, password_expires_at: 2.minutes.ago) }

            it 'redirects to sign in page' do
              execute_raw_request_with_token_in_headers

              expect(response).to have_gitlab_http_status(:found)
              expect(response.location).to end_with('/users/sign_in')
            end
          end

          context 'when password expiration is not applicable' do
            context 'when ldap user' do
              let_it_be(:user) { create(:omniauth_user, provider: 'ldap', password_expires_at: 2.minutes.ago) }

              it 'calls the action normally' do
                execute_raw_request_with_token_in_headers

                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end
        end

        context 'when token is incorrect' do
          let(:token) { 'foobar' }

          it 'redirects to sign in page' do
            execute_raw_request_with_token_in_headers

            expect(response).to have_gitlab_http_status(:found)
            expect(response.location).to end_with('/users/sign_in')
          end
        end
      end
    end

    describe 'caching' do
      def request_file
        get(:show, params: { namespace_id: project.namespace, project_id: project, id: 'master/README.md' })
      end

      it 'sets appropriate caching headers' do
        sign_in create(:user)
        request_file

        expect(response.cache_control[:public]).to eq(true)
        expect(response.cache_control[:max_age]).to eq(60)
        expect(response.cache_control[:no_store]).to be_nil
      end

      context 'when a public project has private repo' do
        let(:project) { create(:project, :public, :repository, :repository_private) }
        let(:user) { create(:user, maintainer_projects: [project]) }

        it 'does not set public caching header' do
          sign_in user
          request_file

          expect(response.header['Cache-Control']).to include('max-age=60, private')
        end
      end

      context 'when If-None-Match header is set' do
        it 'returns a 304 status' do
          request_file

          request.headers['If-None-Match'] = response.headers['ETag']
          request_file

          expect(response).to have_gitlab_http_status(:not_modified)
        end
      end
    end
  end

  def execute_raw_requests(requests:, project:, file_path:, **params)
    requests.times do
      get :show, params: {
        namespace_id: project.namespace,
        project_id: project,
        id: file_path
      }.merge(params)
    end
  end
end
