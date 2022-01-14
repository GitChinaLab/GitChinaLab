# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::InOperatorOptimization::ArrayScopeColumns do
  let(:columns) { [:relative_position, :id] }

  subject(:array_scope_columns) { described_class.new(columns) }

  it 'builds array column names' do
    expect(array_scope_columns.array_aggregated_column_names).to eq(%w[array_cte_relative_position_array array_cte_id_array])
  end

  context 'when no columns are given' do
    let(:columns) { [] }

    it { expect { array_scope_columns }.to raise_error /No array columns were given/ }
  end
end
