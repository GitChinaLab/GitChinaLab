# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module LockRetryMixin
        module ActiveRecordMigrationProxyLockRetries
          def migration_class
            migration.class
          end

          def enable_lock_retries?
            # regular AR migrations don't have this,
            # only ones inheriting from Gitlab::Database::Migration have
            return false unless migration.respond_to?(:enable_lock_retries?)

            migration.enable_lock_retries?
          end
        end

        module ActiveRecordMigratorLockRetries
          # We patch the original method to start a transaction
          # using the WithLockRetries methodology for the whole migration.
          def ddl_transaction(migration, &block)
            if use_transaction?(migration) && migration.enable_lock_retries?
              Gitlab::Database::WithLockRetries.new(
                klass: migration.migration_class,
                logger: Gitlab::BackgroundMigration::Logger
              ).run(raise_on_exhaustion: false, &block)
            else
              super
            end
          end
        end

        def self.patch!
          ActiveRecord::MigrationProxy.prepend(ActiveRecordMigrationProxyLockRetries)
          ActiveRecord::Migrator.prepend(ActiveRecordMigratorLockRetries)
        end
      end
    end
  end
end
