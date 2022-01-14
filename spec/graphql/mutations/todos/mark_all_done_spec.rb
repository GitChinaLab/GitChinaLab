# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::MarkAllDone do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :pending) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :done) }
  let_it_be(:todo3) { create(:todo, user: current_user, author: author, state: :pending) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :pending) }

  let_it_be(:user3) { create(:user) }

  specify { expect(described_class).to require_graphql_authorizations(:update_user) }

  describe '#resolve' do
    it 'marks all pending todos as done' do
      todos = mutation_for(current_user).resolve[:todos]

      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('done')
      expect(todo3.reload.state).to eq('done')
      expect(other_user_todo.reload.state).to eq('pending')

      expect(todos).to contain_exactly(todo1, todo3)
    end

    it 'behaves as expected if there are no todos for the requesting user' do
      todos = mutation_for(user3).resolve[:todos]

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('done')
      expect(todo3.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('pending')

      expect(todos).to be_empty
    end

    context 'when user is not logged in' do
      it 'fails with the expected error' do
        expect { mutation_for(nil).resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end

  def mutation_for(user)
    described_class.new(object: nil, context: { current_user: user }, field: nil)
  end
end
