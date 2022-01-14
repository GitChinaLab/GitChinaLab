# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GlobalId::Deprecations do
  include GlobalIDDeprecationHelpers

  let_it_be(:deprecation_1) { described_class::Deprecation.new(old_model_name: 'Foo::Model', new_model_name: 'Bar', milestone: '9.0') }
  let_it_be(:deprecation_2) { described_class::Deprecation.new(old_model_name: 'Baz', new_model_name: 'Qux::Model', milestone: '10.0') }

  before do
    stub_global_id_deprecations(deprecation_1, deprecation_2)
  end

  describe '.deprecated?' do
    it 'returns a boolean to signal if model name has a deprecation', :aggregate_failures do
      expect(described_class.deprecated?('Foo::Model')).to eq(true)
      expect(described_class.deprecated?('Qux::Model')).to eq(false)
    end
  end

  describe '.deprecation_for' do
    it 'returns the deprecation for the model if it exists', :aggregate_failures do
      expect(described_class.deprecation_for('Foo::Model')).to eq(deprecation_1)
      expect(described_class.deprecation_for('Qux::Model')).to be_nil
    end
  end

  describe '.deprecation_by' do
    it 'returns the deprecation by the model if it exists', :aggregate_failures do
      expect(described_class.deprecation_by('Foo::Model')).to be_nil
      expect(described_class.deprecation_by('Qux::Model')).to eq(deprecation_2)
    end
  end

  describe '.apply_to_graphql_name' do
    it 'returns the corresponding graphql_name of the GID for the new model', :aggregate_failures do
      expect(described_class.apply_to_graphql_name('FooModelID')).to eq('BarID')
      expect(described_class.apply_to_graphql_name('BazID')).to eq('QuxModelID')
    end

    it 'returns the same value if there is no deprecation' do
      expect(described_class.apply_to_graphql_name('ProjectID')).to eq('ProjectID')
    end
  end
end
