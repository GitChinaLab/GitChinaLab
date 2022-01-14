# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification, query_analyzers: false do
  let_it_be(:pipeline, refind: true) { create(:ci_pipeline) }
  let_it_be(:project, refind: true) { create(:project) }

  before do
    allow(Gitlab::Database::QueryAnalyzer.instance).to receive(:all_analyzers).and_return([described_class])
  end

  around do |example|
    Gitlab::Database::QueryAnalyzer.instance.within { example.run }
  end

  shared_examples 'successful examples' do
    context 'outside transaction' do
      it { expect { run_queries }.not_to raise_error }
    end

    context 'within transaction' do
      it do
        Project.transaction do
          expect { run_queries }.not_to raise_error
        end
      end
    end

    context 'within nested transaction' do
      it do
        Project.transaction(requires_new: true) do
          Project.transaction(requires_new: true) do
            expect { run_queries }.not_to raise_error
          end
        end
      end
    end
  end

  context 'when CI and other tables are read in a transaction' do
    def run_queries
      pipeline.reload
      project.reload
    end

    include_examples 'successful examples'
  end

  context 'when only CI data is modified' do
    def run_queries
      pipeline.touch
      project.reload
    end

    include_examples 'successful examples'
  end

  context 'when other data is modified' do
    def run_queries
      pipeline.reload
      project.touch
    end

    include_examples 'successful examples'
  end

  context 'when both CI and other data is modified' do
    def run_queries
      project.touch
      pipeline.touch
    end

    context 'outside transaction' do
      it { expect { run_queries }.not_to raise_error }
    end

    context 'when data modification happens in a transaction' do
      it 'raises error' do
        Project.transaction do
          expect { run_queries }.to raise_error /Cross-database data modification/
        end
      end

      context 'when data modification happens in nested transactions' do
        it 'raises error' do
          Project.transaction(requires_new: true) do
            project.touch
            Project.transaction(requires_new: true) do
              expect { pipeline.touch }.to raise_error /Cross-database data modification/
            end
          end
        end
      end

      context 'when comments are added to the front of query strings' do
        around do |example|
          prepend_comment_was = Marginalia::Comment.prepend_comment
          Marginalia::Comment.prepend_comment = true

          example.run

          Marginalia::Comment.prepend_comment = prepend_comment_was
        end

        it 'raises error' do
          Project.transaction do
            expect { run_queries }.to raise_error /Cross-database data modification/
          end
        end
      end
    end

    context 'when executing a SELECT FOR UPDATE query' do
      def run_queries
        project.touch
        pipeline.lock!
      end

      context 'outside transaction' do
        it { expect { run_queries }.not_to raise_error }
      end

      context 'when data modification happens in a transaction' do
        it 'raises error' do
          Project.transaction do
            expect { run_queries }.to raise_error /Cross-database data modification/
          end
        end

        context 'when the modification is inside a factory save! call' do
          let(:runner) { create(:ci_runner, :project, projects: [build(:project)]) }

          it 'does not raise an error' do
            runner
          end
        end
      end
    end

    context 'when CI association is modified through project' do
      def run_queries
        project.variables.build(key: 'a', value: 'v')
        project.save!
      end

      include_examples 'successful examples'
    end

    describe '.allow_cross_database_modification_within_transaction' do
      it 'skips raising error' do
        expect do
          described_class.allow_cross_database_modification_within_transaction(url: 'gitlab-issue') do
            Project.transaction do
              pipeline.touch
              project.touch
            end
          end
        end.not_to raise_error
      end

      it 'skips raising error on factory creation' do
        expect do
          described_class.allow_cross_database_modification_within_transaction(url: 'gitlab-issue') do
            ApplicationRecord.transaction do
              create(:ci_pipeline)
            end
          end
        end.not_to raise_error
      end
    end
  end

  context 'when some table with a defined schema and another table with undefined gitlab_schema is modified' do
    it 'raises an error including including message about undefined schema' do
      expect do
        Project.transaction do
          project.touch
          project.connection.execute('UPDATE foo_bars_undefined_table SET a=1 WHERE id = -1')
        end
      end.to raise_error /Cross-database data modification.*The gitlab_schema was undefined/
    end
  end

  context 'when execution is rescued with StandardError' do
    it 'raises cross-database data modification exception' do
      expect do
        Project.transaction do
          project.touch
          project.connection.execute('UPDATE foo_bars_undefined_table SET a=1 WHERE id = -1')
        end
      rescue StandardError
        # Ensures that standard rescue does not silence errors
      end.to raise_error /Cross-database data modification.*The gitlab_schema was undefined/
    end
  end

  context 'when uniquiness validation is tested', type: :model do
    subject { build(:ci_variable) }

    it 'does not raise exceptions' do
      expect do
        is_expected.to validate_uniqueness_of(:key).scoped_to(:project_id, :environment_scope).with_message(/\(\w+\) has already been taken/)
      end.not_to raise_error
    end
  end

  context 'when doing rollback in a suppressed block' do
    it 'does not raise misaligned transactions exception' do
      expect do
        # This is non-materialised transaction:
        # 1. the transaction will be open on a write (project.touch) (in a suppressed block)
        # 2. the rescue will be handled outside of suppressed block
        #
        # This will create misaligned boundaries since BEGIN
        # of transaction will be executed within a suppressed block
        Project.transaction do
          described_class.with_suppressed do
            project.touch

            raise 'force rollback'
          end

          # the ensure of `.transaction` executes `ROLLBACK TO SAVEPOINT`
        end
      end.to raise_error /force rollback/
    end
  end
end
