# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CustomerRelationsContact'] do
  let(:fields) { %i[id organization first_name last_name phone email description created_at updated_at] }

  it { expect(described_class.graphql_name).to eq('CustomerRelationsContact') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_crm_contact) }
end
