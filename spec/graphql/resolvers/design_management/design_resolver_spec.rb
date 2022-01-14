# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DesignManagement::DesignResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::DesignManagement::DesignType)
  end

  before do
    enable_design_management
  end

  describe '#resolve' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:project) { issue.project }
    let_it_be(:first_version) { create(:design_version) }
    let_it_be(:first_design) { create(:design, issue: issue, versions: [first_version]) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:design_on_other_issue) do
      create(:design, issue: create(:issue, project: project), versions: [create(:design_version)])
    end

    let(:args) { { id: GitlabSchema.id_from_object(first_design).to_s } }
    let(:gql_context) { { current_user: current_user } }

    before do
      project.add_developer(current_user)
    end

    context 'when the user cannot see designs' do
      let(:gql_context) { { current_user: create(:user) } }

      it 'returns nothing' do
        expect(resolve_design).to be_nil
      end
    end

    context 'when no argument has been passed' do
      let(:args) { {} }

      it 'raises an error' do
        expect { resolve_design }.to raise_error(::Gitlab::Graphql::Errors::ArgumentError, /must/)
      end
    end

    context 'when both arguments have been passed' do
      let(:args) { { filename: first_design.filename, id: GitlabSchema.id_from_object(first_design).to_s } }

      it 'raises an error' do
        expect { resolve_design }.to raise_error(::Gitlab::Graphql::Errors::ArgumentError, /may/)
      end
    end

    context 'by ID' do
      it 'returns the specified design' do
        expect(resolve_design).to eq(first_design)
      end

      context 'the ID belongs to a design on another issue' do
        let(:args) { { id: global_id_of(design_on_other_issue) } }

        it 'returns nothing' do
          expect(resolve_design).to be_nil
        end
      end

      context 'the ID does not belong to a design at all' do
        let(:args) { { id: global_id_of(issue) } }
        let(:msg) { /does not represent an instance of DesignManagement::Design/ }

        it 'complains meaningfully' do
          expect { resolve_design }.to raise_error(msg)
        end
      end
    end

    context 'by filename' do
      let(:args) { { filename: first_design.filename } }

      it 'returns the specified design' do
        expect(resolve_design).to eq(first_design)
      end

      context 'the filename belongs to a design on another issue' do
        let(:args) { { filename: design_on_other_issue.filename } }

        it 'returns nothing' do
          expect(resolve_design).to be_nil
        end
      end
    end
  end

  def resolve_design
    resolve(described_class, obj: issue.design_collection, args: args, ctx: gql_context)
  end
end
