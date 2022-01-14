# frozen_string_literal: true

module OauthApplications
  extend ActiveSupport::Concern

  CREATED_SESSION_KEY = :oauth_applications_created

  included do
    before_action :prepare_scopes, only: [:create, :update]
  end

  def prepare_scopes
    scopes = params.fetch(:doorkeeper_application, {}).fetch(:scopes, nil)

    if scopes
      params[:doorkeeper_application][:scopes] = scopes.join(' ')
    end
  end

  def set_created_session
    session[CREATED_SESSION_KEY] = true
  end

  def get_created_session
    session.delete(CREATED_SESSION_KEY) || false
  end

  def load_scopes
    @scopes ||= Doorkeeper.configuration.scopes
  end

  def permitted_params
    %i{name redirect_uri scopes confidential expire_access_tokens}
  end

  def application_params
    params
      .require(:doorkeeper_application)
      .permit(*permitted_params)
  end
end
