# frozen_string_literal: true

class Admin::ApplicationsController < Admin::ApplicationController
  include OauthApplications

  before_action :set_application, only: [:show, :edit, :update, :destroy]
  before_action :load_scopes, only: [:new, :create, :edit, :update]

  feature_category :authentication_and_authorization

  def index
    applications = ApplicationsFinder.new.execute
    @applications = Kaminari.paginate_array(applications).page(params[:page])
    @application_counts = OauthAccessToken.distinct_resource_owner_counts(@applications)
  end

  def show
    @created = get_created_session
  end

  def new
    # Default access tokens to expire. This preserves backward compatibility
    # with existing applications. This will be removed in 15.0.
    # Removal issue: https://gitlab.com/gitlab-org/gitlab/-/issues/340848
    @application = Doorkeeper::Application.new(expire_access_tokens: true)
  end

  def edit
  end

  def create
    @application = Applications::CreateService.new(current_user, application_params).execute(request)

    if @application.persisted?
      flash[:notice] = I18n.t(:notice, scope: [:doorkeeper, :flash, :applications, :create])

      set_created_session

      redirect_to admin_application_url(@application)
    else
      render :new
    end
  end

  def update
    if @application.update(application_params)
      redirect_to admin_application_path(@application), notice: _('Application was successfully updated.')
    else
      render :edit
    end
  end

  def destroy
    @application.destroy
    redirect_to admin_applications_url, status: :found, notice: _('Application was successfully destroyed.')
  end

  private

  def set_application
    @application = ApplicationsFinder.new(id: params[:id]).execute
  end

  def permitted_params
    super << :trusted
  end

  def application_params
    super.tap do |params|
      params[:owner] = nil
    end
  end
end
