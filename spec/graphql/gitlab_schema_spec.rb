# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema do
  let_it_be(:connections) { GitlabSchema.connections.all_wrappers }

  let(:user) { build :user }

  it 'uses batch loading' do
    expect(field_instrumenters).to include(BatchLoader::GraphQL)
  end

  it 'enables the generic instrumenter' do
    expect(field_instrumenters).to include(instance_of(::Gitlab::Graphql::GenericTracing))
  end

  it 'has the base mutation' do
    expect(described_class.mutation).to eq(::Types::MutationType)
  end

  it 'has the base query' do
    expect(described_class.query).to eq(::Types::QueryType)
  end

  it 'paginates active record relations using `Pagination::Keyset::Connection`' do
    connection = connections[ActiveRecord::Relation]

    expect(connection).to eq(Gitlab::Graphql::Pagination::Keyset::Connection)
  end

  it 'paginates ExternallyPaginatedArray using `Pagination::ExternallyPaginatedArrayConnection`' do
    connection = connections[Gitlab::Graphql::ExternallyPaginatedArray]

    expect(connection).to eq(Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection)
  end

  it 'sets an appropriate validation timeout' do
    expect(described_class.validate_timeout).to be <= 0.2.seconds
  end

  describe '.execute' do
    describe 'setting query `max_complexity` and `max_depth`' do
      subject(:result) { described_class.execute('query', **kwargs).query }

      shared_examples 'sets default limits' do
        specify do
          expect(result).to have_attributes(
            max_complexity: GitlabSchema::DEFAULT_MAX_COMPLEXITY,
            max_depth: GitlabSchema::DEFAULT_MAX_DEPTH
          )
        end
      end

      context 'with no context' do
        let(:kwargs) { {} }

        include_examples 'sets default limits'
      end

      context 'with no :current_user' do
        let(:kwargs) { { context: {} } }

        include_examples 'sets default limits'
      end

      context 'with anonymous user' do
        let(:kwargs) { { context: { current_user: nil } } }

        include_examples 'sets default limits'
      end

      context 'with a logged in user' do
        let(:kwargs) { { context: { current_user: user } } }

        it 'sets authenticated user limits' do
          expect(result).to have_attributes(
            max_complexity: GitlabSchema::AUTHENTICATED_MAX_COMPLEXITY,
            max_depth: GitlabSchema::AUTHENTICATED_MAX_DEPTH
          )
        end
      end

      context 'with an admin user' do
        let(:kwargs) { { context: { current_user: build(:user, :admin) } } }

        it 'sets admin/authenticated user limits' do
          expect(result).to have_attributes(
            max_complexity: GitlabSchema::ADMIN_MAX_COMPLEXITY,
            max_depth: GitlabSchema::AUTHENTICATED_MAX_DEPTH
          )
        end
      end

      context 'when limits passed as kwargs' do
        let(:kwargs) { { max_complexity: 1234, max_depth: 4321 } }

        it 'sets limits from the kwargs' do
          expect(result).to have_attributes(
            max_complexity: 1234,
            max_depth: 4321
          )
        end
      end
    end
  end

  describe '.id_from_object' do
    it 'returns a global id' do
      expect(described_class.id_from_object(build(:project, id: 1))).to be_a(GlobalID)
    end

    it "raises a meaningful error if a global id couldn't be generated" do
      expect { described_class.id_from_object(build(:wiki_directory)) }
        .to raise_error(RuntimeError, /include `GlobalID::Identification` into/i)
    end
  end

  describe '.object_from_id' do
    context 'with subclasses of `ApplicationRecord`' do
      let_it_be(:user) { create(:user) }

      it 'returns the correct record' do
        result = described_class.object_from_id(user.to_global_id.to_s)

        expect(result.sync).to eq(user)
      end

      it 'returns the correct record, of the expected type' do
        result = described_class.object_from_id(user.to_global_id.to_s, expected_type: ::User)

        expect(result.sync).to eq(user)
      end

      it 'fails if the type does not match' do
        expect do
          described_class.object_from_id(user.to_global_id.to_s, expected_type: ::Project)
        end.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end

      it 'batchloads the queries' do
        user1 = create(:user)
        user2 = create(:user)

        expect do
          [described_class.object_from_id(user1.to_global_id),
           described_class.object_from_id(user2.to_global_id)].map(&:sync)
        end.not_to exceed_query_limit(1)
      end
    end

    context 'with classes that are not ActiveRecord subclasses and have implemented .lazy_find' do
      it 'returns the correct record' do
        note = create(:discussion_note_on_merge_request)

        result = described_class.object_from_id(note.to_global_id)

        expect(result.sync).to eq(note)
      end

      it 'batchloads the queries' do
        note1 = create(:discussion_note_on_merge_request)
        note2 = create(:discussion_note_on_merge_request)

        expect do
          [described_class.object_from_id(note1.to_global_id),
           described_class.object_from_id(note2.to_global_id)].map(&:sync)
        end.not_to exceed_query_limit(1)
      end
    end

    context 'with other classes' do
      # We cannot use an anonymous class here as `GlobalID` expects `.name` not
      # to return `nil`
      before do
        test_global_id = Class.new do
          include GlobalID::Identification
          attr_accessor :id

          def initialize(id)
            @id = id
          end
        end

        stub_const('TestGlobalId', test_global_id)
      end

      it 'falls back to a regular find' do
        result = TestGlobalId.new(123)

        expect(TestGlobalId).to receive(:find).with("123").and_return(result)

        expect(described_class.object_from_id(result.to_global_id)).to eq(result)
      end
    end

    it 'raises the correct error on invalid input' do
      expect { described_class.object_from_id("bogus id") }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
    end
  end

  describe 'validate_max_errors' do
    it 'reports at most 5 errors' do
      query = <<~GQL
        query {
          currentUser {
            x: id
            x: bot
            x: username
            x: state
            x: name

            x: id
            x: bot
            x: username
            x: state
            x: name

            badField
            veryBadField
            alsoNotAGoodField
          }
        }
      GQL

      result = described_class.execute(query)

      expect(result.to_h['errors'].count).to eq 5
    end
  end

  describe '.parse_gid' do
    let_it_be(:global_id) { 'gid://gitlab/TestOne/2147483647' }

    subject(:parse_gid) { described_class.parse_gid(global_id) }

    before do
      test_base = Class.new
      test_one = Class.new(test_base)
      test_two = Class.new(test_base)
      test_three = Class.new(test_base)

      stub_const('TestBase', test_base)
      stub_const('TestOne', test_one)
      stub_const('TestTwo', test_two)
      stub_const('TestThree', test_three)
    end

    it 'parses the gid' do
      gid = parse_gid

      expect(gid.model_id).to eq '2147483647'
      expect(gid.model_class).to eq TestOne
    end

    context 'when gid is malformed' do
      let_it_be(:global_id) { 'malformed://gitlab/TestOne/2147483647' }

      it 'raises an error' do
        expect { parse_gid }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, "#{global_id} is not a valid GitLab ID.")
      end
    end

    context 'when using expected_type' do
      it 'accepts a single type' do
        gid = described_class.parse_gid(global_id, expected_type: TestOne)

        expect(gid.model_class).to eq TestOne
      end

      it 'accepts an ancestor type' do
        gid = described_class.parse_gid(global_id, expected_type: TestBase)

        expect(gid.model_class).to eq TestOne
      end

      it 'rejects an unknown type' do
        expect { described_class.parse_gid(global_id, expected_type: TestTwo) }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, "#{global_id} is not a valid ID for TestTwo.")
      end

      context 'when expected_type is an array' do
        subject(:parse_gid) { described_class.parse_gid(global_id, expected_type: [TestOne, TestTwo]) }

        context 'when global_id is of type TestOne' do
          it 'returns an object of an expected type' do
            expect(parse_gid.model_class).to eq TestOne
          end
        end

        context 'when global_id is of type TestTwo' do
          let_it_be(:global_id) { 'gid://gitlab/TestTwo/2147483647' }

          it 'returns an object of an expected type' do
            expect(parse_gid.model_class).to eq TestTwo
          end
        end

        context 'when global_id is of type TestThree' do
          let_it_be(:global_id) { 'gid://gitlab/TestThree/2147483647' }

          it 'rejects an unknown type' do
            expect { parse_gid }
              .to raise_error(Gitlab::Graphql::Errors::ArgumentError, "#{global_id} is not a valid ID for TestOne, TestTwo.")
          end
        end
      end
    end
  end

  def field_instrumenters
    described_class.instrumenters[:field] + described_class.instrumenters[:field_after_built_ins]
  end
end
