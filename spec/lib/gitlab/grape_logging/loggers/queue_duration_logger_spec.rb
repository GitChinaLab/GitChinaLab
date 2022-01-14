# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::QueueDurationLogger do
  subject { described_class.new }

  describe ".parameters" do
    let(:start_time) { Time.new(2018, 01, 01) }

    describe 'when no proxy time is available' do
      let(:mock_request) { double('env', env: {}) }

      it 'returns an empty hash' do
        expect(subject.parameters(mock_request, nil)).to eq({})
      end
    end

    describe 'when a proxy time is available' do
      let(:mock_request) do
        double('env',
          env: {
            'HTTP_GITLAB_WORKHORSE_PROXY_START' => (start_time - 1.hour).to_i * (10**9)
          }
        )
      end

      it 'returns the correct duration in seconds' do
        travel_to(start_time) do
          subject.before

          expect(subject.parameters(mock_request, nil)).to eq( { 'queue_duration_s': 1.hour.to_f })
        end
      end
    end
  end
end
