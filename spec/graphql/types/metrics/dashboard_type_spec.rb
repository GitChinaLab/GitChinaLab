# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MetricsDashboard'] do
  specify { expect(described_class.graphql_name).to eq('MetricsDashboard') }

  it 'has the expected fields' do
    expected_fields = %w[
        path annotations schema_validation_warnings
      ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'annotations field' do
    subject { described_class.fields['annotations'] }

    it { is_expected.to have_graphql_type(Types::Metrics::Dashboards::AnnotationType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::Metrics::Dashboards::AnnotationResolver) }
  end
end
