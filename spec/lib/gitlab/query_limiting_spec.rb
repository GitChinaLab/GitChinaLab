# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QueryLimiting, :request_store do
  describe '.enabled_for_env?' do
    it 'returns true in a test environment' do
      expect(described_class.enabled_for_env?).to eq(true)
    end

    it 'returns true in a development environment' do
      stub_rails_env('development')
      stub_rails_env('development')

      expect(described_class.enabled_for_env?).to eq(true)
    end

    it 'returns false on GitLab.com' do
      stub_rails_env('production')
      allow(Gitlab).to receive(:com?).and_return(true)

      expect(described_class.enabled_for_env?).to eq(false)
    end

    it 'returns false in a non GitLab.com' do
      allow(Gitlab).to receive(:com?).and_return(false)
      stub_rails_env('production')

      expect(described_class.enabled_for_env?).to eq(false)
    end
  end

  shared_context 'disable and enable' do |result|
    let(:transaction) { Gitlab::QueryLimiting::Transaction.new }
    let(:code) do
      proc do
        2.times { User.count }
      end
    end

    before do
      allow(Gitlab::QueryLimiting::Transaction)
        .to receive(:current)
        .and_return(transaction)
    end
  end

  describe '.disable!' do
    include_context 'disable and enable'

    it 'raises an ArgumentError when an invalid issue URL is given' do
      expect { described_class.disable!('foo') }
        .to raise_error(ArgumentError)
    end

    it 'stops the number of SQL queries from being incremented' do
      described_class.disable!('https://example.com')

      expect { code.call }.not_to change { transaction.count }
    end
  end

  describe '.enable!' do
    include_context 'disable and enable'

    it 'allows the number of SQL queries to be incremented' do
      described_class.enable!

      expect { code.call }.to change { transaction.count }.by(2)
    end
  end

  describe '#enabled?' do
    it 'returns true when enabled' do
      Gitlab::SafeRequestStore[:query_limiting_disabled] = nil

      expect(described_class).to be_enabled
    end

    it 'returns false when disabled' do
      Gitlab::SafeRequestStore[:query_limiting_disabled] = true

      expect(described_class).not_to be_enabled
    end
  end
end
