# frozen_string_literal: true

class Projects::ProjectMembersController < Projects::ApplicationController
  include MembershipActions
  include MembersPresentation
  include SortingHelper

  # Authorize
  before_action :authorize_admin_project_member!, except: [:index, :leave, :request_access]

  feature_category :authentication_and_authorization

  def index
    @sort = params[:sort].presence || sort_value_name

    @skip_groups = @project.invited_group_ids
    @skip_groups += @project.group.self_and_ancestors_ids if @project.group

    @group_links = @project.project_group_links
    @group_links = @group_links.search(params[:search_groups]) if params[:search_groups].present?

    if can?(current_user, :admin_project_member, @project)
      @invited_members = present_members(invited_members)
      @requesters = present_members(AccessRequestsFinder.new(@project).execute(current_user))
    end

    @project_members = present_members(non_invited_members.page(params[:page]))

    @project_member = @project.project_members.new
  end

  def import
    @projects = Project.visible_to_user_and_access_level(current_user, Gitlab::Access::MAINTAINER).order_id_desc
  end

  def apply_import
    source_project = Project.find(params[:source_project_id])

    if can?(current_user, :admin_project_member, source_project)
      status = @project.team.import(source_project, current_user)
      notice = status ? "Successfully imported" : "Import failed"
    else
      return render_404
    end

    redirect_to(project_project_members_path(project), notice: notice)
  end

  # MembershipActions concern
  alias_method :membershipable, :project

  private

  def members
    @members ||= MembersFinder
      .new(@project, current_user, params: filter_params)
      .execute(include_relations: requested_relations)
  end

  def invited_members
    members.invite.with_invited_user_state
  end

  def non_invited_members
    members.non_invite
  end

  def filter_params
    params.permit(:search).merge(sort: @sort)
  end

  def membershipable_members
    project.members
  end

  def plain_source_type
    'project'
  end

  def source_type
    _("project")
  end

  def members_page_url
    project_project_members_path(project)
  end

  def root_params_key
    :project_member
  end
end

Projects::ProjectMembersController.prepend_mod_with('Projects::ProjectMembersController')
