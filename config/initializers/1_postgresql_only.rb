# frozen_string_literal: true

raise "PostgreSQL is the only supported database from GitLab 12.1" unless
  ApplicationRecord.database.postgresql?

Gitlab::Database.check_postgres_version_and_print_warning
