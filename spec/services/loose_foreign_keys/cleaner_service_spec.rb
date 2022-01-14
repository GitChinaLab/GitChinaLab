# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::CleanerService do
  let(:schema) { ApplicationRecord.connection.current_schema }
  let(:deleted_records) do
    [
      LooseForeignKeys::DeletedRecord.new(fully_qualified_table_name: "#{schema}.projects", primary_key_value: non_existing_record_id),
      LooseForeignKeys::DeletedRecord.new(fully_qualified_table_name: "#{schema}.projects", primary_key_value: non_existing_record_id)
    ]
  end

  let(:loose_fk_definition) do
    ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
      'issues',
      'projects',
      {
        column: 'project_id',
        on_delete: :async_nullify,
        gitlab_schema: :gitlab_main
      }
    )
  end

  subject(:cleaner_service) do
    described_class.new(
      loose_foreign_key_definition: loose_fk_definition,
      connection: ApplicationRecord.connection,
      deleted_parent_records: deleted_records)
  end

  context 'when invalid foreign key definition is passed' do
    context 'when invalid on_delete argument was given' do
      before do
        loose_fk_definition.options[:on_delete] = :invalid
      end

      it 'raises KeyError' do
        expect { cleaner_service.execute }.to raise_error(StandardError, /Invalid on_delete argument/)
      end
    end
  end

  describe 'query generation' do
    context 'when single primary key is used' do
      let(:issue) { create(:issue) }

      let(:deleted_records) do
        [
          LooseForeignKeys::DeletedRecord.new(fully_qualified_table_name: "#{schema}.projects", primary_key_value: issue.project_id)
        ]
      end

      it 'generates an IN query for nullifying the rows' do
        expected_query = %{UPDATE "issues" SET "project_id" = NULL WHERE ("issues"."id") IN (SELECT "issues"."id" FROM "issues" WHERE "issues"."project_id" IN (#{issue.project_id}) LIMIT 500)}
        expect(ApplicationRecord.connection).to receive(:execute).with(expected_query).and_call_original

        cleaner_service.execute

        issue.reload
        expect(issue.project_id).to be_nil
      end

      it 'generates an IN query for deleting the rows' do
        loose_fk_definition.options[:on_delete] = :async_delete

        expected_query = %{DELETE FROM "issues" WHERE ("issues"."id") IN (SELECT "issues"."id" FROM "issues" WHERE "issues"."project_id" IN (#{issue.project_id}) LIMIT 1000)}
        expect(ApplicationRecord.connection).to receive(:execute).with(expected_query).and_call_original

        cleaner_service.execute

        expect(Issue.exists?(id: issue.id)).to eq(false)
      end
    end

    context 'when composite primary key is used' do
      let!(:user) { create(:user) }
      let!(:project) { create(:project) }

      let(:loose_fk_definition) do
        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
          'project_authorizations',
          'users',
          {
            column: 'user_id',
            on_delete: :async_delete,
            gitlab_schema: :gitlab_main
          }
        )
      end

      let(:deleted_records) do
        [
          LooseForeignKeys::DeletedRecord.new(fully_qualified_table_name: "#{schema}.users", primary_key_value: user.id)
        ]
      end

      subject(:cleaner_service) do
        described_class.new(
          loose_foreign_key_definition: loose_fk_definition,
          connection: ApplicationRecord.connection,
          deleted_parent_records: deleted_records
        )
      end

      before do
        project.add_developer(user)
      end

      it 'generates an IN query for deleting the rows' do
        expected_query = %{DELETE FROM "project_authorizations" WHERE ("project_authorizations"."user_id", "project_authorizations"."project_id", "project_authorizations"."access_level") IN (SELECT "project_authorizations"."user_id", "project_authorizations"."project_id", "project_authorizations"."access_level" FROM "project_authorizations" WHERE "project_authorizations"."user_id" IN (#{user.id}) LIMIT 1000)}
        expect(ApplicationRecord.connection).to receive(:execute).with(expected_query).and_call_original

        cleaner_service.execute

        expect(ProjectAuthorization.exists?(user_id: user.id)).to eq(false)
      end

      context 'when the query generation is incorrect (paranoid check)' do
        it 'raises error if the foreign key condition is missing' do
          expect_next_instance_of(LooseForeignKeys::CleanerService) do |instance|
            expect(instance).to receive(:delete_query).and_return('wrong query')
          end

          expect { cleaner_service.execute }.to raise_error /FATAL: foreign key condition is missing from the generated query/
        end
      end
    end

    context 'when with_skip_locked parameter is true' do
      subject(:cleaner_service) do
        described_class.new(
          loose_foreign_key_definition: loose_fk_definition,
          connection: ApplicationRecord.connection,
          deleted_parent_records: deleted_records,
          with_skip_locked: true
        )
      end

      it 'generates a query with the SKIP LOCKED clause' do
        expect(ApplicationRecord.connection).to receive(:execute).with(/FOR UPDATE SKIP LOCKED/).and_call_original

        cleaner_service.execute
      end
    end
  end
end
