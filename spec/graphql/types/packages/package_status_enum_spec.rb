# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageStatus'] do
  it 'exposes all package statuses' do
    expect(described_class.values.keys).to contain_exactly(*%w[DEFAULT HIDDEN PROCESSING ERROR])
  end
end
