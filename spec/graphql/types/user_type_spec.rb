# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['User'] do
  specify { expect(described_class.graphql_name).to eq('User') }

  specify do
    runtime_type = described_class.resolve_type(build(:user), {})

    expect(runtime_type).to require_graphql_authorizations(:read_user)
  end

  it 'has the expected fields' do
    expected_fields = %w[
      id
      bot
      user_permissions
      snippets
      name
      username
      email
      publicEmail
      avatarUrl
      webUrl
      webPath
      todos
      state
      status
      location
      authoredMergeRequests
      assignedMergeRequests
      reviewRequestedMergeRequests
      groupMemberships
      groupCount
      projectMemberships
      starredProjects
      callouts
      namespace
      timelogs
      groups
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'name field' do
    let_it_be(:admin) { create(:user, :admin)}
    let_it_be(:user) { create(:user) }
    let_it_be(:requested_user) { create(:user, name: 'John Smith') }
    let_it_be(:requested_project_bot) { create(:user, :project_bot, name: 'Project bot') }
    let_it_be(:project) { create(:project, :public) }

    before do
      project.add_maintainer(requested_project_bot)
    end

    let(:username) { requested_user.username }

    let(:query) do
      %(
        query {
          user(username: "#{username}") {
            name
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json.dig('data', 'user', 'name') }

    context 'user requests' do
      let(:current_user) { user }

      context 'a user' do
        it 'returns name' do
          expect(subject).to eq('John Smith')
        end
      end

      context 'a project bot' do
        let(:username) { requested_project_bot.username }

        context 'when requester is nil' do
          let(:current_user) { nil }

          it 'returns `****`' do
            expect(subject).to eq('****')
          end
        end

        it 'returns `****` for a regular user' do
          expect(subject).to eq('****')
        end

        context 'when requester is a project maintainer' do
          before do
            project.add_maintainer(user)
          end

          it 'returns name' do
            expect(subject).to eq('Project bot')
          end
        end
      end
    end

    context 'admin requests', :enable_admin_mode do
      let(:current_user) { admin }

      context 'a user' do
        it 'returns name' do
          expect(subject).to eq('John Smith')
        end
      end

      context 'a project bot' do
        let(:username) { requested_project_bot.username }

        it 'returns name' do
          expect(subject).to eq('Project bot')
        end
      end
    end
  end

  describe 'snippets field' do
    subject { described_class.fields['snippets'] }

    it 'returns snippets' do
      is_expected.to have_graphql_type(Types::SnippetType.connection_type)
      is_expected.to have_graphql_resolver(Resolvers::Users::SnippetsResolver)
    end
  end

  describe 'callouts field' do
    subject { described_class.fields['callouts'] }

    it 'returns user callouts' do
      is_expected.to have_graphql_type(Types::UserCalloutType.connection_type)
    end
  end

  describe 'timelogs field' do
    subject { described_class.fields['timelogs'] }

    it 'returns user timelogs' do
      is_expected.to have_graphql_resolver(Resolvers::TimelogResolver)
      is_expected.to have_graphql_type(Types::TimelogType.connection_type)
    end
  end
end
