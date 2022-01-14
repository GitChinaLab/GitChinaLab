# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/prevent_index_creation'

RSpec.describe RuboCop::Cop::Migration::PreventIndexCreation do
  subject(:cop) { described_class.new }

  let(:forbidden_tables) { %w(ci_builds) }
  let(:forbidden_tables_list) { forbidden_tables.join(', ') }

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when adding an index to a forbidden table' do
      context 'when table_name is a symbol' do
        it "registers an offense when add_index is used", :aggregate_failures do
          forbidden_tables.each do |table_name|
            expect_offense(<<~RUBY)
              def change
                add_index :#{table_name}, :protected
                ^^^^^^^^^ Adding new index to #{forbidden_tables_list} is forbidden, see https://gitlab.com/gitlab-org/gitlab/-/issues/332886
              end
            RUBY
          end
        end

        it "registers an offense when add_concurrent_index is used", :aggregate_failures do
          forbidden_tables.each do |table_name|
            expect_offense(<<~RUBY)
              def change
                add_concurrent_index :#{table_name}, :protected
                ^^^^^^^^^^^^^^^^^^^^ Adding new index to #{forbidden_tables_list} is forbidden, see https://gitlab.com/gitlab-org/gitlab/-/issues/332886
              end
            RUBY
          end
        end
      end

      context 'when table_name is a string' do
        it "registers an offense when add_index is used", :aggregate_failures do
          forbidden_tables.each do |table_name|
            expect_offense(<<~RUBY)
              def change
                add_index "#{table_name}", :protected
                ^^^^^^^^^ Adding new index to #{forbidden_tables_list} is forbidden, see https://gitlab.com/gitlab-org/gitlab/-/issues/332886
              end
            RUBY
          end
        end

        it "registers an offense when add_concurrent_index is used", :aggregate_failures do
          forbidden_tables.each do |table_name|
            expect_offense(<<~RUBY)
              def change
                add_concurrent_index "#{table_name}", :protected
                ^^^^^^^^^^^^^^^^^^^^ Adding new index to #{forbidden_tables_list} is forbidden, see https://gitlab.com/gitlab-org/gitlab/-/issues/332886
              end
            RUBY
          end
        end
      end

      context 'when table_name is a constant' do
        it "registers an offense when add_concurrent_index is used", :aggregate_failures do
          expect_offense(<<~RUBY)
            INDEX_NAME = "index_name"
            TABLE_NAME = :ci_builds
            disable_ddl_transaction!

            def change
              add_concurrent_index TABLE_NAME, :protected
              ^^^^^^^^^^^^^^^^^^^^ Adding new index to #{forbidden_tables_list} is forbidden, see https://gitlab.com/gitlab-org/gitlab/-/issues/332886
            end
          RUBY
        end
      end
    end

    context 'when adding an index to a regular table' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def change
            add_index :ci_pipelines, :locked
          end
        RUBY
      end

      context 'when using a constant' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            disable_ddl_transaction!

            TABLE_NAME = "not_forbidden"

            def up
              add_concurrent_index TABLE_NAME, :protected
            end
          RUBY
        end
      end
    end
  end

  context 'when outside of migration' do
    it 'does not register an offense' do
      expect_no_offenses('def change; add_index :table, :column; end')
    end
  end
end
