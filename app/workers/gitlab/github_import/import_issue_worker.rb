# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportIssueWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::Issue
      end

      def importer_class
        Importer::IssueAndLabelLinksImporter
      end

      def object_type
        :issue
      end
    end
  end
end
