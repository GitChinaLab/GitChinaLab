# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class PreventCrossDatabaseModification < Database::QueryAnalyzers::Base
        CrossDatabaseModificationAcrossUnsupportedTablesError = Class.new(QueryAnalyzerError)

        # This method will allow cross database modifications within the block
        # Example:
        #
        # allow_cross_database_modification_within_transaction(url: 'url-to-an-issue') do
        #   create(:build) # inserts ci_build and project record in one transaction
        # end
        def self.allow_cross_database_modification_within_transaction(url:, &blk)
          self.with_suppressed(true, &blk)
        end

        # This method will prevent cross database modifications within the block
        # if it was allowed previously
        def self.with_cross_database_modification_prevented(&blk)
          self.with_suppressed(false, &blk)
        end

        def self.begin!
          super

          context.merge!({
            transaction_depth_by_db: Hash.new { |h, k| h[k] = 0 },
            modified_tables_by_db: Hash.new { |h, k| h[k] = Set.new }
          })
        end

        def self.enabled?
          ::Feature::FlipperFeature.table_exists? &&
            Feature.enabled?(:detect_cross_database_modification, default_enabled: :yaml)
        end

        def self.requires_tracking?(parsed)
          # The transaction boundaries always needs to be tracked regardless of suppress behavior
          self.transaction_begin?(parsed) || self.transaction_end?(parsed)
        end

        # rubocop:disable Metrics/AbcSize
        def self.analyze(parsed)
          database = ::Gitlab::Database.db_config_name(parsed.connection)
          sql = parsed.sql

          # We ignore BEGIN in tests as this is the outer transaction for
          # DatabaseCleaner
          if self.transaction_begin?(parsed)
            context[:transaction_depth_by_db][database] += 1

            return
          elsif self.transaction_end?(parsed)
            context[:transaction_depth_by_db][database] -= 1
            if context[:transaction_depth_by_db][database] == 0
              context[:modified_tables_by_db][database].clear
            elsif context[:transaction_depth_by_db][database] < 0
              context[:transaction_depth_by_db][database] = 0
              raise CrossDatabaseModificationAcrossUnsupportedTablesError, "Misaligned cross-DB transactions discovered at query #{sql}. This could be a bug in #{self.class} or a valid issue to investigate. Read more at https://docs.gitlab.com/ee/development/database/multiple_databases.html#removing-cross-database-transactions ."
            end

            return
          end

          return unless self.in_transaction?
          return if in_factory_bot_create?

          # PgQuery might fail in some cases due to limited nesting:
          # https://github.com/pganalyze/pg_query/issues/209
          tables = sql.downcase.include?(' for update') ? parsed.pg.tables : parsed.pg.dml_tables

          # We have some code where plans and gitlab_subscriptions are lazily
          # created and this causes lots of spec failures
          # https://gitlab.com/gitlab-org/gitlab/-/issues/343394
          tables -= %w[plans gitlab_subscriptions]

          return if tables.empty?

          # All migrations will write to schema_migrations in the same transaction.
          # It's safe to ignore this since schema_migrations exists in all
          # databases
          return if tables == ['schema_migrations']

          context[:modified_tables_by_db][database].merge(tables)
          all_tables = context[:modified_tables_by_db].values.map(&:to_a).flatten
          schemas = ::Gitlab::Database::GitlabSchema.table_schemas(all_tables)

          if schemas.many?
            message = "Cross-database data modification of '#{schemas.to_a.join(", ")}' were detected within " \
              "a transaction modifying the '#{all_tables.to_a.join(", ")}' tables." \
              "Please refer to https://docs.gitlab.com/ee/development/database/multiple_databases.html#removing-cross-database-transactions for details on how to resolve this exception."

            if schemas.any? { |s| s.to_s.start_with?("undefined") }
              message += " The gitlab_schema was undefined for one or more of the tables in this transaction. Any new tables must be added to lib/gitlab/database/gitlab_schemas.yml ."
            end

            raise CrossDatabaseModificationAcrossUnsupportedTablesError, message
          end
        rescue CrossDatabaseModificationAcrossUnsupportedTablesError => e
          ::Gitlab::ErrorTracking.track_exception(e, { gitlab_schemas: schemas, tables: all_tables, query: parsed.sql })
          raise if raise_exception?
        end
        # rubocop:enable Metrics/AbcSize

        def self.transaction_begin?(parsed)
          # We ignore BEGIN or START in tests
          unless Rails.env.test?
            return true if transaction_stmt?(parsed, :TRANS_STMT_BEGIN)
            return true if transaction_stmt?(parsed, :TRANS_STMT_START)
          end

          # SAVEPOINT
          return true if transaction_stmt?(parsed, :TRANS_STMT_SAVEPOINT)

          false
        end

        def self.transaction_end?(parsed)
          # We ignore ROLLBACK or COMMIT in tests
          unless Rails.env.test?
            return true if transaction_stmt?(parsed, :TRANS_STMT_COMMIT)
            return true if transaction_stmt?(parsed, :TRANS_STMT_COMMIT_PREPARED)
            return true if transaction_stmt?(parsed, :TRANS_STMT_ROLLBACK)
            return true if transaction_stmt?(parsed, :TRANS_STMT_ROLLBACK_PREPARED)
          end

          # RELEASE (SAVEPOINT) or ROLLBACK TO (SAVEPOINT)
          return true if transaction_stmt?(parsed, :TRANS_STMT_RELEASE)
          return true if transaction_stmt?(parsed, :TRANS_STMT_ROLLBACK_TO)

          false
        end

        # Known kinds: https://github.com/pganalyze/pg_query/blob/f6588703deb9d7a94b87b34b7c3bab240087fbc4/ext/pg_query/include/nodes/parsenodes.h#L3050
        def self.transaction_stmt?(parsed, kind)
          parsed.pg.tree.stmts.map(&:stmt).any? do |stmt|
            stmt.node == :transaction_stmt && stmt.transaction_stmt.kind == kind
          end
        end

        # We only raise in tests for now otherwise some features will be broken
        # in development. For now we've mostly only added allowlist based on
        # spec names. Until we have allowed all the violations inline we don't
        # want to raise in development.
        def self.raise_exception?
          Rails.env.test?
        end

        def self.in_transaction?
          context[:transaction_depth_by_db].values.any?(&:positive?)
        end

        # We ignore execution in the #create method from FactoryBot
        # because it is not representative of real code we run in
        # production. There are far too many false positives caused
        # by instantiating objects in different `gitlab_schema` in a
        # FactoryBot `create`.
        def self.in_factory_bot_create?
          Rails.env.test? && caller_locations.any? do |l|
            l.path.end_with?('lib/factory_bot/evaluation.rb') && l.label == 'create' ||
            l.path.end_with?('lib/factory_bot/strategy/create.rb') ||
            l.path.end_with?('shoulda/matchers/active_record/validate_uniqueness_of_matcher.rb') && l.label == 'create_existing_record'
          end
        end
      end
    end
  end
end
