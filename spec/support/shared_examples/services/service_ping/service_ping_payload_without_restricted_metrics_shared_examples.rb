# frozen_string_literal: true

RSpec.shared_examples 'service ping payload without restricted metrics' do
  specify do
    aggregate_failures do
      restricted_metrics.each do |metric|
        is_expected.not_to have_usage_metric metric['key_path']
      end
    end
  end
end
