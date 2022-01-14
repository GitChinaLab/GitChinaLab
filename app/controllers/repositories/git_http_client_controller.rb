# frozen_string_literal: true

module Repositories
  class GitHttpClientController < Repositories::ApplicationController
    include ActionController::HttpAuthentication::Basic
    include KerberosSpnegoHelper
    include Gitlab::Utils::StrongMemoize

    attr_reader :authentication_result, :redirected_path

    delegate :authentication_abilities, to: :authentication_result, allow_nil: true
    delegate :type, to: :authentication_result, allow_nil: true, prefix: :auth_result

    # Git clients will not know what authenticity token to send along
    skip_around_action :set_session_storage
    skip_before_action :verify_authenticity_token

    prepend_before_action :authenticate_user, :parse_repo_path

    feature_category :source_code_management

    def authenticated_user
      authentication_result&.user || authentication_result&.deploy_token
    end

    private

    def user
      authenticated_user
    end

    def download_request?
      raise NotImplementedError
    end

    def upload_request?
      raise NotImplementedError
    end

    def authenticate_user
      @authentication_result = Gitlab::Auth::Result::EMPTY

      if allow_basic_auth? && basic_auth_provided?
        login, password = user_name_and_password(request)

        if handle_basic_authentication(login, password)
          return # Allow access
        end
      elsif allow_kerberos_spnego_auth? && spnego_provided?
        kerberos_user = find_kerberos_user

        if kerberos_user
          @authentication_result = Gitlab::Auth::Result.new(
            kerberos_user, nil, :kerberos, Gitlab::Auth.full_authentication_abilities)

          send_final_spnego_response
          return # Allow access
        end
      elsif http_download_allowed?

        @authentication_result = Gitlab::Auth::Result.new(nil, project, :none, [:download_code])

        return # Allow access
      end

      send_challenges
      render plain: "HTTP Basic: Access denied\n", status: :unauthorized
    rescue Gitlab::Auth::MissingPersonalAccessTokenError
      render_missing_personal_access_token
    end

    def basic_auth_provided?
      has_basic_credentials?(request)
    end

    def send_challenges
      challenges = []
      challenges << 'Basic realm="GitLab"' if allow_basic_auth?
      challenges << spnego_challenge if allow_kerberos_spnego_auth?
      headers['Www-Authenticate'] = challenges.join("\n") if challenges.any?
    end

    def container
      parse_repo_path unless defined?(@container)

      @container
    end

    def project
      parse_repo_path unless defined?(@project)

      @project
    end

    def repository_path
      @repository_path ||= params[:repository_path]
    end

    def parse_repo_path
      @container, @project, @repo_type, @redirected_path = Gitlab::RepoPath.parse(repository_path)
    end

    def render_missing_personal_access_token
      render plain: "HTTP Basic: Access denied\n" \
                    "You must use a personal access token with 'read_repository' or 'write_repository' scope for Git over HTTP.\n" \
                    "You can generate one at #{profile_personal_access_tokens_url}",
            status: :unauthorized
    end

    def repository
      strong_memoize(:repository) do
        repo_type.repository_for(container)
      end
    end

    def repo_type
      parse_repo_path unless defined?(@repo_type)

      @repo_type
    end

    def handle_basic_authentication(login, password)
      @authentication_result = Gitlab::Auth.find_for_git_client(
        login, password, project: project, ip: request.ip)

      @authentication_result.success?
    end

    def ci?
      authentication_result.ci?(project)
    end

    def http_download_allowed?
      Gitlab::ProtocolAccess.allowed?('http') &&
      download_request? &&
      container &&
      Guest.can?(repo_type.guest_read_ability, container)
    end
  end
end

Repositories::GitHttpClientController.prepend_mod_with('Repositories::GitHttpClientController')
