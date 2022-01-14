# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::Restore do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :done, target: issue) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :pending, target: issue) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :done) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  before_all do
    project.add_developer(current_user)
  end

  specify { expect(described_class).to require_graphql_authorizations(:update_todo) }

  describe '#resolve' do
    it 'restores a single todo' do
      result = restore_mutation(todo1)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')

      todo = result[:todo]
      expect(todo.id).to eq(todo1.id)
      expect(todo.state).to eq('pending')
    end

    it 'handles a todo which is already pending as expected' do
      result = restore_mutation(todo2)

      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')

      todo = result[:todo]
      expect(todo.id).to eq(todo2.id)
      expect(todo.state).to eq('pending')
    end

    it 'ignores requests for todos which do not belong to the current user' do
      expect { restore_mutation(other_user_todo) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)

      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')
    end

    it 'raises error for invalid GID' do
      expect { mutation.resolve(id: author.to_global_id.to_s) }
        .to raise_error(::GraphQL::CoercionError)

      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')
    end
  end

  def restore_mutation(todo)
    mutation.resolve(id: global_id_of(todo))
  end
end
