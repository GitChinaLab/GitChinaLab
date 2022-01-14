# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlAdapter
      module DumpSchemaVersionsMixin
        extend ActiveSupport::Concern

        def dump_schema_information # :nodoc:
          Gitlab::Database::SchemaMigrations.touch_all(self) if Gitlab.dev_or_test_env?

          nil
        end
      end
    end
  end
end
