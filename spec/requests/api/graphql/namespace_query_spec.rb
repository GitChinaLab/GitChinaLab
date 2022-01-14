# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:group_namespace) { create(:group) }
  let_it_be(:user_namespace) { create(:user_namespace, owner: user) }
  let_it_be(:project_namespace) { create(:project_namespace, parent: group_namespace) }

  describe '.namespace' do
    subject { post_graphql(query, current_user: current_user) }

    let(:current_user) { user }

    let(:query) { graphql_query_for(:namespace, { 'fullPath' => target_namespace.full_path }, all_graphql_fields_for('Namespace')) }
    let(:query_result) { graphql_data['namespace'] }

    shared_examples 'retrieving a namespace' do
      context 'authorised query' do
        before do
          subject
        end

        it_behaves_like 'a working graphql query'

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name
          )
        end
      end

      context 'unauthorised query' do
        before do
          subject
        end

        context 'anonymous user' do
          let(:current_user) { nil }

          it 'does not retrieve the record' do
            expect(query_result).to be_nil
          end
        end

        context 'the current user does not have permission' do
          let(:current_user) { other_user }

          it 'does not retrieve the record' do
            expect(query_result).to be_nil
          end
        end
      end
    end

    it_behaves_like 'retrieving a namespace' do
      let(:target_namespace) { group_namespace }

      before do
        group_namespace.add_developer(user)
      end
    end

    it_behaves_like 'retrieving a namespace' do
      let(:target_namespace) { user_namespace }
    end

    context 'does not retrieve project namespace' do
      let(:target_namespace) { project_namespace }

      before do
        subject
      end

      it 'does not retrieve the record' do
        expect(query_result).to be_nil
      end
    end
  end
end
