# frozen_string_literal: true

module BitbucketServer
  module Representation
    class Activity < Representation::Base
      def comment?
        action == 'COMMENTED'
      end

      def inline_comment?
        !!(comment? && comment_anchor)
      end

      def comment
        return unless comment?

        @comment ||=
          if inline_comment?
            PullRequestComment.new(raw)
          else
            Comment.new(raw)
          end
      end

      # TODO Move this into MergeEvent
      def merge_event?
        action == 'MERGED'
      end

      def committer_user
        commit.dig('committer', 'displayName')
      end

      def committer_email
        commit.dig('committer', 'emailAddress')
      end

      def merge_timestamp
        timestamp = commit['committerTimestamp']

        self.class.convert_timestamp(timestamp)
      end

      def merge_commit
        commit['id']
      end

      def created_at
        self.class.convert_timestamp(created_date)
      end

      private

      def commit
        raw.fetch('commit', {})
      end

      def action
        raw['action']
      end

      def comment_anchor
        raw['commentAnchor']
      end

      def created_date
        raw['createdDate']
      end
    end
  end
end
