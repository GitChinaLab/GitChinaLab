# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SetupHelper::Workhorse do
  describe '.make' do
    subject { described_class.make }

    context 'when there is a gmake' do
      it 'returns gmake' do
        expect(Gitlab::Popen).to receive(:popen).with(%w[which gmake]).and_return(['/usr/bin/gmake', 0])

        expect(subject).to eq 'gmake'
      end
    end

    context 'when there is no gmake' do
      it 'returns make' do
        expect(Gitlab::Popen).to receive(:popen).with(%w[which gmake]).and_return(['', 1])

        expect(subject).to eq 'make'
      end
    end
  end

  describe '.redis_url' do
    it 'matches the SharedState URL' do
      expect(Gitlab::Redis::SharedState).to receive(:url).and_return('foo')

      expect(described_class.redis_url).to eq('foo')
    end
  end

  describe '.redis_db' do
    subject { described_class.redis_db }

    it 'matches the SharedState DB' do
      expect(Gitlab::Redis::SharedState).to receive(:params).and_return(db: 1)

      is_expected.to eq(1)
    end

    it 'defaults to 0 if unspecified' do
      expect(Gitlab::Redis::SharedState).to receive(:params).and_return({})

      is_expected.to eq(0)
    end
  end
end
