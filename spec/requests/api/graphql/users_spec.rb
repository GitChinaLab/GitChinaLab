# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Users' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user, created_at: 1.day.ago) }
  let_it_be(:user1) { create(:user, created_at: 2.days.ago) }
  let_it_be(:user2) { create(:user, created_at: 3.days.ago) }
  let_it_be(:user3) { create(:user, created_at: 4.days.ago) }

  describe '.users' do
    shared_examples 'a working users query' do
      it_behaves_like 'a working graphql query' do
        before do
          post_graphql(query, current_user: current_user)
        end
      end

      it 'includes a list of users' do
        post_graphql(query)

        expect(graphql_data.dig('users', 'nodes')).not_to be_empty
      end
    end

    context 'with no arguments' do
      let_it_be(:query) { graphql_query_for(:users, { usernames: [user1.username] }, 'nodes { id }') }

      it_behaves_like 'a working users query'
    end

    context 'with a list of usernames' do
      let(:query) { graphql_query_for(:users, { usernames: [user1.username] }, 'nodes { id }') }

      it_behaves_like 'a working users query'
    end

    context 'with a list of IDs' do
      let(:query) { graphql_query_for(:users, { ids: [user1.to_global_id.to_s] }, 'nodes { id }') }

      it_behaves_like 'a working users query'
    end

    context 'when usernames and ids parameter are used' do
      let_it_be(:query) { graphql_query_for(:users, { ids: user1.to_global_id.to_s, usernames: user1.username }, 'nodes { id }') }

      it 'displays an error' do
        post_graphql(query)

        expect(graphql_errors).to include(
          a_hash_including('message' => a_string_matching(%r{Provide either a list of usernames or ids}))
        )
      end
    end

    context 'when admins is true' do
      let_it_be(:admin) { create(:user, :admin) }
      let_it_be(:another_admin) { create(:user, :admin) }

      let(:query) { graphql_query_for(:users, { admins: true }, 'nodes { id }') }

      context 'current user is not an admin' do
        let(:post_query) { post_graphql(query, current_user: current_user) }

        it_behaves_like 'a working users query'

        it 'includes all non-admin users', :aggregate_failures do
          post_graphql(query)

          expect(graphql_data.dig('users', 'nodes')).to include(
            { "id" => user1.to_global_id.to_s },
            { "id" => user2.to_global_id.to_s },
            { "id" => user3.to_global_id.to_s },
            { "id" => current_user.to_global_id.to_s },
            { "id" => admin.to_global_id.to_s },
            { "id" => another_admin.to_global_id.to_s }
          )
        end
      end

      context 'when current user is an admin' do
        it_behaves_like 'a working users query'

        it 'includes only admins', :aggregate_failures do
          post_graphql(query, current_user: admin)

          expect(graphql_data.dig('users', 'nodes')).to include(
            { "id" => another_admin.to_global_id.to_s },
            { "id" => admin.to_global_id.to_s }
          )

          expect(graphql_data.dig('users', 'nodes')).not_to include(
            { "id" => user1.to_global_id.to_s },
            { "id" => user2.to_global_id.to_s },
            { "id" => user3.to_global_id.to_s },
            { "id" => current_user.to_global_id.to_s }
          )
        end
      end
    end
  end

  describe 'sorting and pagination' do
    let_it_be(:data_path) { [:users] }

    def pagination_query(params)
      graphql_query_for(:users, params, "#{page_info} nodes { id }")
    end

    context 'when sorting by created_at' do
      let_it_be(:ascending_users) { [user3, user2, user1, current_user].map { |u| global_id_of(u) } }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :CREATED_ASC }
          let(:first_param) { 1 }
          let(:all_records) { ascending_users }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :CREATED_DESC }
          let(:first_param) { 1 }
          let(:all_records) { ascending_users.reverse }
        end
      end
    end
  end
end
