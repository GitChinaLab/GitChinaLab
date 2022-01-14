# frozen_string_literal: true

module Todos
  module Destroy
    class EntityLeaveService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :user, :entity

      def initialize(user_id, entity_id, entity_type)
        unless %w(Group Project).include?(entity_type)
          raise ArgumentError, "#{entity_type} is not an entity user can leave"
        end

        @user = UserFinder.new(user_id).find_by_id
        @entity = entity_type.constantize.find_by(id: entity_id) # rubocop: disable CodeReuse/ActiveRecord
      end

      def execute
        return unless entity && user

        # if at least reporter, all entities including confidential issues can be accessed
        return if user_has_reporter_access?

        remove_confidential_resource_todos
        remove_group_todos

        if entity.private?
          remove_project_todos
        else
          enqueue_private_features_worker
        end
      end

      private

      def enqueue_private_features_worker
        projects.each do |project|
          TodosDestroyer::PrivateFeaturesWorker.perform_async(project.id, user.id)
        end
      end

      def remove_confidential_resource_todos
        Todo
          .for_target(confidential_issues.select(:id))
          .for_type(Issue.name)
          .for_user(user)
          .delete_all
      end

      def remove_project_todos
        # Issues are viewable by guests (even in private projects), so remove those todos
        # from projects without guest access
        Todo
          .for_project(non_authorized_guest_projects)
          .for_user(user)
          .delete_all

        # MRs require reporter access, so remove those todos that are not authorized
        Todo
          .for_project(non_authorized_reporter_projects)
          .for_type(MergeRequest.name)
          .for_user(user)
          .delete_all
      end

      def remove_group_todos
        return unless entity.is_a?(Namespace)

        Todo
          .for_group(unauthorized_private_groups)
          .for_user(user)
          .delete_all
      end

      def projects
        condition = case entity
                    when Project
                      { id: entity.id }
                    when Namespace
                      { namespace_id: non_authorized_reporter_groups }
                    end

        Project.where(condition) # rubocop: disable CodeReuse/ActiveRecord
      end

      def authorized_reporter_projects
        user.authorized_projects(Gitlab::Access::REPORTER).select(:id)
      end

      def authorized_guest_projects
        user.authorized_projects(Gitlab::Access::GUEST).select(:id)
      end

      def non_authorized_reporter_projects
        projects.id_not_in(authorized_reporter_projects)
      end

      def non_authorized_guest_projects
        projects.id_not_in(authorized_guest_projects)
      end

      def authorized_reporter_groups
        GroupsFinder.new(user, min_access_level: Gitlab::Access::REPORTER).execute.select(:id)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def unauthorized_private_groups
        return [] unless entity.is_a?(Namespace)

        groups = entity.self_and_descendants.private_only

        groups.select(:id)
          .id_not_in(GroupsFinder.new(user, all_available: false).execute.select(:id).reorder(nil))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def non_authorized_reporter_groups
        entity.self_and_descendants.select(:id)
          .id_not_in(authorized_reporter_groups)
      end

      def user_has_reporter_access?
        return unless entity.is_a?(Namespace)

        entity.member?(User.find(user.id), Gitlab::Access::REPORTER)
      end

      def confidential_issues
        assigned_ids = IssueAssignee.select(:issue_id).for_assignee(user)

        Issue
          .in_projects(projects)
          .confidential_only
          .not_in_projects(authorized_reporter_projects)
          .not_authored_by(user)
          .id_not_in(assigned_ids)
      end
    end
  end
end

Todos::Destroy::EntityLeaveService.prepend_mod_with('Todos::Destroy::EntityLeaveService')
