# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Snippets::BlobsResolver do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Snippets::BlobType.connection_type)
  end

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:snippet) { create(:personal_snippet, :private, :repository, author: current_user) }

    context 'when user is not authorized' do
      let(:other_user) { create(:user) }

      it 'redacts the field' do
        expect(resolve_blobs(snippet, user: other_user)).to be_nil
      end
    end

    context 'when using no filter' do
      it 'returns all snippet blobs' do
        result = resolve_blobs(snippet, args: {})

        expect(result).to match_array(snippet.list_files.map do |file|
          have_attributes(path: file)
        end)
      end
    end

    context 'when using filters' do
      context 'when paths is a single string' do
        it 'returns an array of files' do
          path = 'CHANGELOG'

          expect(resolve_blobs(snippet, paths: [path])).to contain_exactly(have_attributes(path: path))
        end
      end

      context 'the argument does not match anything' do
        it 'returns an empty result' do
          expect(resolve_blobs(snippet, paths: ['does not exist'])).to be_empty
        end
      end

      context 'when paths is an array of string' do
        it 'returns an array of files' do
          paths = ['CHANGELOG', 'README.md']

          expect(resolve_blobs(snippet, paths: paths)).to match_array(paths.map do |file|
            have_attributes(path: file)
          end)
        end
      end
    end
  end

  def resolve_blobs(snippet, user: current_user, paths: [], args: { paths: paths })
    resolve(described_class, args: args, ctx: { current_user: user }, obj: snippet)
  end
end
