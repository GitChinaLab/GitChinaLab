# frozen_string_literal: true

module BulkImports
  module FileTransfer
    class ProjectConfig < BaseConfig
      SKIPPED_RELATIONS = %w(
        project_members
        group_members
      ).freeze

      def import_export_yaml
        ::Gitlab::ImportExport.config_file
      end

      def skipped_relations
        SKIPPED_RELATIONS
      end
    end
  end
end
