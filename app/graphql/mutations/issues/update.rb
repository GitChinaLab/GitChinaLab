# frozen_string_literal: true

module Mutations
  module Issues
    class Update < Base
      graphql_name 'UpdateIssue'

      include CommonMutationArguments

      argument :title, GraphQL::Types::String,
               required: false,
               description: copy_field_description(Types::IssueType, :title)

      argument :milestone_id, GraphQL::Types::ID, # rubocop: disable Graphql/IDType
               required: false,
               description: 'ID of the milestone to assign to the issue. On update milestone will be removed if set to null.'

      argument :add_label_ids, [GraphQL::Types::ID],
               required: false,
               description: 'IDs of labels to be added to the issue.'

      argument :remove_label_ids, [GraphQL::Types::ID],
               required: false,
               description: 'IDs of labels to be removed from the issue.'

      argument :label_ids, [GraphQL::Types::ID],
               required: false,
               description: 'IDs of labels to be set. Replaces existing issue labels.'

      argument :state_event, Types::IssueStateEventEnum,
               description: 'Close or reopen an issue.',
               required: false

      def resolve(project_path:, iid:, **args)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        args = parse_arguments(args)

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])
        ::Issues::UpdateService.new(project: project, current_user: current_user, params: args, spam_params: spam_params).execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end

      def ready?(label_ids: [], add_label_ids: [], remove_label_ids: [], **args)
        if label_ids.any? && (add_label_ids.any? || remove_label_ids.any?)
          raise Gitlab::Graphql::Errors::ArgumentError, 'labelIds is mutually exclusive with any of addLabelIds or removeLabelIds'
        end

        super
      end

      private

      def parse_arguments(args)
        args[:add_label_ids] = parse_label_ids(args[:add_label_ids])
        args[:remove_label_ids] = parse_label_ids(args[:remove_label_ids])
        args[:label_ids] = parse_label_ids(args[:label_ids])

        args
      end

      def parse_label_ids(ids)
        ids&.map do |gid|
          GitlabSchema.parse_gid(gid, expected_type: ::Label).model_id
        rescue Gitlab::Graphql::Errors::ArgumentError
          gid
        end
      end
    end
  end
end

Mutations::Issues::Update.prepend_mod_with('Mutations::Issues::Update')
