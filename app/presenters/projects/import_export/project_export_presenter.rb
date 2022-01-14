# frozen_string_literal: true

module Projects
  module ImportExport
    class ProjectExportPresenter < Gitlab::View::Presenter::Delegated
      include ActiveModel::Serializers::JSON

      presents ::Project, as: :project

      # TODO: Remove `ActiveModel::Serializers::JSON` inclusion as it's duplicate
      delegator_override_with ActiveModel::Serializers::JSON
      delegator_override_with ActiveModel::Naming
      delegator_override :include_root_in_json, :include_root_in_json?

      delegator_override :project_members
      def project_members
        super + converted_group_members
      end

      delegator_override :description
      def description
        self.respond_to?(:override_description) ? override_description : super
      end

      delegator_override :protected_branches
      def protected_branches
        project.exported_protected_branches
      end

      private

      def converted_group_members
        group_members.each do |group_member|
          group_member.source_type = 'Project' # Make group members project members of the future import
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def group_members
        return [] unless current_user.can?(:admin_group, project.group)

        # We need `.connected_to_user` here otherwise when a group has an
        # invitee, it would make the following query return 0 rows since a NULL
        # user_id would be present in the subquery
        non_null_user_ids = project.project_members.connected_to_user.select(:user_id)
        GroupMembersFinder.new(project.group).execute.where.not(user_id: non_null_user_ids)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
