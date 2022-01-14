# frozen_string_literal: true

class BaseDiscussionEntity < Grape::Entity
  include RequestAwareEntity
  include NotesHelper

  expose :id
  expose :reply_id
  expose :project_id
  expose :commit_id

  expose :confidential?, as: :confidential
  expose :diff_discussion?, as: :diff_discussion
  expose :expanded?, as: :expanded
  expose :for_commit?, as: :for_commit
  expose :individual_note?, as: :individual_note
  expose :resolvable?, as: :resolvable
  expose :resolved_by_push?, as: :resolved_by_push

  expose :truncated_diff_lines, using: DiffLineEntity, if: -> (d, _) { d.diff_discussion? && d.on_text? && (d.expanded? || render_truncated_diff_lines?) }

  with_options if: -> (d, _) { d.diff_discussion? } do
    expose :active?, as: :active
    expose :line_code
    expose :diff_file, using: DiscussionDiffFileEntity
  end

  with_options if: -> (d, _) { d.diff_discussion? && !d.legacy_diff_discussion? } do
    expose :position
    expose :original_position
  end

  expose :discussion_path do |discussion|
    discussion_path(discussion)
  end

  with_options if: -> (d, _) { d.resolvable? } do
    expose :resolve_path do |discussion|
      resolve_project_merge_request_discussion_path(discussion.project, discussion.noteable, discussion.id)
    end

    expose :resolve_with_issue_path do |discussion|
      new_project_issue_path(discussion.project, merge_request_to_resolve_discussions_of: discussion.noteable.iid, discussion_to_resolve: discussion.id) if discussion&.project&.issues_enabled?
    end
  end

  expose :truncated_diff_lines_path, if: -> (d, _) { !d.expanded? && !render_truncated_diff_lines? } do |discussion|
    project_merge_request_discussion_path(discussion.project, discussion.noteable, discussion)
  end

  private

  def render_truncated_diff_lines?
    options.fetch(:render_truncated_diff_lines, false)
  end
end
