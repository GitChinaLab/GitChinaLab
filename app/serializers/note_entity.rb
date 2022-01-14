# frozen_string_literal: true

class NoteEntity < API::Entities::Note
  include RequestAwareEntity
  include NotesHelper

  expose :id do |note|
    # resource events are represented as notes too, but don't
    # have ID, discussion ID is used for them instead
    note.id ? note.id.to_s : note.discussion_id
  end

  expose :type

  expose :author, using: NoteUserEntity

  unexpose :note, as: :body
  expose :note

  expose :redacted_note_html, as: :note_html

  expose :last_edited_at, if: -> (note, _) { note.edited? }
  expose :last_edited_by, using: NoteUserEntity, if: -> (note, _) { note.edited? }

  expose :current_user do
    expose :can_edit do |note|
      can?(current_user, :admin_note, note)
    end

    expose :can_award_emoji do |note|
      can?(current_user, :award_emoji, note)
    end

    expose :can_resolve do |note|
      note.resolvable? && can?(current_user, :resolve_note, note)
    end

    expose :can_resolve_discussion do |note|
      discussion = options.fetch(:discussion, nil) || note.discussion
      discussion.resolvable? && discussion.can_resolve?(current_user)
    end
  end

  expose :suggestions, using: SuggestionEntity
  expose :resolved?, as: :resolved
  expose :resolvable?, as: :resolvable

  expose :resolved_by, using: NoteUserEntity

  expose :system_note_icon_name, if: -> (note, _) { note.system? } do |note|
    SystemNoteHelper.system_note_icon_name(note)
  end

  expose :outdated_line_change_path, if: -> (note, _) { note.show_outdated_changes? } do |note|
    outdated_line_change_namespace_project_note_path(namespace_id: note.project.namespace, project_id: note.project, id: note)
  end

  expose :is_noteable_author do |note|
    note.noteable_author?(request.noteable)
  end

  expose :discussion_id do |note|
    note.discussion_id(request.noteable)
  end

  expose :emoji_awardable?, as: :emoji_awardable
  expose :award_emoji, if: -> (note, _) { note.emoji_awardable? }, using: AwardEmojiEntity

  expose :report_abuse_path, if: -> (note, _) { note.author_id } do |note|
    new_abuse_report_path(user_id: note.author_id, ref_url: Gitlab::UrlBuilder.build(note))
  end

  expose :noteable_note_url do |note|
    noteable_note_url(note)
  end

  expose :resolve_path, if: -> (note, _) { note.part_of_discussion? && note.resolvable? } do |note|
    resolve_project_merge_request_discussion_path(note.project, note.noteable, note.discussion_id)
  end

  expose :resolve_with_issue_path, if: -> (note, _) { note.part_of_discussion? && note.resolvable? } do |note|
    new_project_issue_path(note.project, merge_request_to_resolve_discussions_of: note.noteable.iid, discussion_to_resolve: note.discussion_id)
  end

  expose :attachment, using: NoteAttachmentEntity, if: -> (note, _) { note.attachment? }

  expose :cached_markdown_version

  # Correctly rendering a note requires some background information about any
  # discussion it is part of. This is essential for the notes endpoint, but
  # optional for the discussions endpoint, which will include the discussion
  # along with the note
  expose :discussion, as: :base_discussion, using: BaseDiscussionEntity, if: -> (_, _) { with_base_discussion? }

  private

  def discussion
    @discussion ||= object.to_discussion(request.noteable)
  end

  def current_user
    request.current_user
  end

  def with_base_discussion?
    options.fetch(:with_base_discussion, true)
  end
end

NoteEntity.prepend_mod_with('NoteEntity')
