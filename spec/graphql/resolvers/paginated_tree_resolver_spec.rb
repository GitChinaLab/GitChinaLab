# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::PaginatedTreeResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Tree::TreeType.connection_type)
  end

  describe '#resolve', :aggregate_failures do
    subject { resolve_repository(args, opts) }

    let(:args) { { ref: 'master' } }
    let(:opts) { {} }

    let(:start_cursor) { subject.start_cursor }
    let(:end_cursor) { subject.end_cursor }
    let(:items) { subject.items }
    let(:entries) { items.first.entries }

    it 'resolves to a collection with a tree object' do
      expect(items.first).to be_an_instance_of(Tree)

      expect(start_cursor).to be_nil
      expect(end_cursor).to be_blank
      expect(entries.count).to eq(repository.tree.entries.count)
    end

    context 'with recursive option' do
      let(:args) { super().merge(recursive: true) }

      it 'resolve to a recursive tree' do
        expect(entries[4].path).to eq('files/html')
      end
    end

    context 'with limited max_page_size' do
      let(:opts) { { max_page_size: 5 } }

      it 'resolves to a pagination collection with a tree object' do
        expect(items.first).to be_an_instance_of(Tree)

        expect(start_cursor).to be_nil
        expect(end_cursor).to be_present
        expect(entries.count).to eq(5)
      end
    end

    context 'when repository does not exist' do
      before do
        allow(repository).to receive(:exists?).and_return(false)
      end

      it 'returns nil' do
        is_expected.to be(nil)
      end
    end

    describe 'Cursor pagination' do
      context 'when cursor is invalid' do
        let(:args) { super().merge(after: 'invalid') }

        it { expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError) }
      end

      it 'returns all tree entries during cursor pagination' do
        cursor = nil

        expected_entries = repository.tree.entries.map(&:path)
        collected_entries = []

        loop do
          result = resolve_repository(args.merge(after: cursor), max_page_size: 10)

          collected_entries += result.items.first.entries.map(&:path)

          expect(result.start_cursor).to eq(cursor)
          cursor = result.end_cursor

          break if cursor.blank?
        end

        expect(collected_entries).to match_array(expected_entries)
      end
    end
  end

  def resolve_repository(args, opts = {})
    field_options = described_class.field_options.merge(
      owner: resolver_parent,
      name: 'field_value'
    ).merge(opts)

    field = ::Types::BaseField.new(**field_options)
    resolve_field(field, repository, args: args, object_type: resolver_parent)
  end
end
