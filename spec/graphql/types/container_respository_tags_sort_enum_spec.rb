# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryTagSort'] do
  specify { expect(described_class.graphql_name).to eq('ContainerRepositoryTagSort') }

  it 'exposes all the existing issue sort values' do
    expect(described_class.values.keys).to include(
      *%w[NAME_ASC NAME_DESC]
    )
  end
end
