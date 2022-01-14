# frozen_string_literal: true

module Gitlab
  module Database
    module LooseForeignKeys
      def self.definitions_by_table
        @definitions_by_table ||= definitions.group_by(&:to_table).with_indifferent_access.freeze
      end

      def self.definitions
        @definitions ||= loose_foreign_keys_yaml.flat_map do |child_table_name, configs|
          configs.map { |config| build_definition(child_table_name, config) }
        end.freeze
      end

      def self.build_definition(child_table_name, config)
        parent_table_name = config.fetch('table')

        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
          child_table_name,
          parent_table_name,
          {
            column: config.fetch('column'),
            on_delete: config.fetch('on_delete').to_sym,
            gitlab_schema: GitlabSchema.table_schema(child_table_name)
          }
        )
      end

      def self.loose_foreign_keys_yaml
        @loose_foreign_keys_yaml ||= YAML.load_file(Rails.root.join('lib/gitlab/database/gitlab_loose_foreign_keys.yml'))
      end

      private_class_method :build_definition
      private_class_method :loose_foreign_keys_yaml
    end
  end
end
