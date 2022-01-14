# frozen_string_literal: true

module Gitlab
  module Database
    class SchemaCleaner
      attr_reader :original_schema

      def initialize(original_schema)
        @original_schema = original_schema
      end

      def clean(io)
        structure = original_schema.dup

        # Remove noise
        structure.gsub!(/^COMMENT ON EXTENSION.*/, '')
        structure.gsub!(/^SET.+/, '')
        structure.gsub!(/^SELECT pg_catalog\.set_config\('search_path'.+/, '')
        structure.gsub!(/^--.*/, "\n")

        # We typically don't assume we're working with the public schema.
        # pg_dump uses fully qualified object names though, since we have multiple schemas
        # in the database.
        #
        # The intention here is to not introduce an assumption about the standard schema,
        # unless we have a good reason to do so.
        structure.gsub!(/public\.(\w+)/, '\1')
        structure.gsub!(/CREATE EXTENSION IF NOT EXISTS (\w+) WITH SCHEMA public;/, 'CREATE EXTENSION IF NOT EXISTS \1;')

        structure.gsub!(/\n{3,}/, "\n\n")

        io << structure.strip
        io << "\n"

        nil
      end
    end
  end
end
