# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['JobArtifactFileType'] do
  it 'exposes all job artifact file types' do
    expect(described_class.values.keys).to contain_exactly(
      *::Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.keys.map(&:to_s).map(&:upcase)
    )
  end
end
