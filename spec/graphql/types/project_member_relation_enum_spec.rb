# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ProjectMemberRelationEnum do
  specify { expect(described_class.graphql_name).to eq('ProjectMemberRelation') }

  it 'exposes all the existing project member relation type values' do
    expect(described_class.values.keys).to contain_exactly('DIRECT', 'INHERITED', 'DESCENDANTS', 'INVITED_GROUPS')
  end
end
