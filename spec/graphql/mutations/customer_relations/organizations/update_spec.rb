# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CustomerRelations::Organizations::Update do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:name) { 'GitLab' }
  let(:default_rate) { 1000.to_f }
  let(:description) { 'VIP' }
  let(:does_not_exist_or_no_permission) { Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR }
  let(:organization) { create(:organization, group: group) }
  let(:attributes) do
    {
      id: organization.to_global_id,
      name: name,
      default_rate: default_rate,
      description: description
    }
  end

  describe '#resolve' do
    subject(:resolve_mutation) do
      described_class.new(object: nil, context: { current_user: user }, field: nil).resolve(
        attributes
      )
    end

    context 'when the user does not have permission to update an organization' do
      before do
        group.add_reporter(user)
      end

      it 'raises an error' do
        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          .with_message(does_not_exist_or_no_permission)
      end
    end

    context 'when the organization does not exist' do
      it 'raises an error' do
        attributes[:id] = "gid://gitlab/CustomerRelations::Organization/#{non_existing_record_id}"

        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          .with_message(does_not_exist_or_no_permission)
      end
    end

    context 'when the user has permission to update an organization' do
      before_all do
        group.add_developer(user)
      end

      it 'updates the organization with correct values' do
        expect(resolve_mutation[:organization]).to have_attributes(attributes)
      end

      context 'when the feature is disabled' do
        before do
          stub_feature_flags(customer_relations: false)
        end

        it 'raises an error' do
          expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
            .with_message("The resource that you are attempting to access does not exist or you don't have permission to perform this action")
        end
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:admin_crm_organization) }
end
