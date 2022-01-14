# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::SidekiqClientMiddleware do
  let(:middleware) { described_class.new }

  let(:worker_class) { 'TestDataConsistencyWorker' }
  let(:job) { { "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e" } }

  before do
    skip_feature_flags_yaml_validation
    skip_default_enabled_yaml_check
  end

  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  def run_middleware
    middleware.call(worker_class, job, nil, nil) {}
  end

  describe '#call', :database_replica do
    shared_context 'data consistency worker class' do |data_consistency, feature_flag|
      let(:expected_consistency) { data_consistency }
      let(:worker_class) do
        Class.new do
          def self.name
            'TestDataConsistencyWorker'
          end

          include ApplicationWorker

          data_consistency data_consistency, feature_flag: feature_flag

          def perform(*args)
          end
        end
      end

      before do
        stub_const('TestDataConsistencyWorker', worker_class)
      end
    end

    shared_examples_for 'job data consistency' do
      it "sets job data consistency" do
        run_middleware

        expect(job['worker_data_consistency']).to eq(expected_consistency)
      end
    end

    shared_examples_for 'does not pass database locations' do
      it 'does not pass database locations', :aggregate_failures do
        run_middleware

        expect(job['wal_locations']).to be_nil
      end

      include_examples 'job data consistency'
    end

    shared_examples_for 'mark data consistency location' do |data_consistency|
      include_context 'data consistency worker class', data_consistency, :load_balancing_for_test_data_consistency_worker

      let(:location) { '0/D525E3A8' }

      context 'when feature flag is disabled' do
        let(:expected_consistency) { :always }

        before do
          stub_feature_flags(load_balancing_for_test_data_consistency_worker: false)
        end

        include_examples 'does not pass database locations'
      end

      context 'when write was not performed' do
        before do
          allow(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_primary?).and_return(false)
        end

        it 'passes database_replica_location' do
          expected_location = {}

          Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
            expect(lb.host)
              .to receive(:database_replica_location)
              .and_return(location)

            expected_location[lb.name] = location
          end

          run_middleware

          expect(job['wal_locations']).to eq(expected_location)
        end

        include_examples 'job data consistency'
      end

      context 'when write was performed' do
        before do
          allow(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_primary?).and_return(true)
        end

        it 'passes primary write location', :aggregate_failures do
          expected_location = {}

          Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
            expect(lb)
              .to receive(:primary_write_location)
              .and_return(location)

            expected_location[lb.name] = location
          end

          run_middleware

          expect(job['wal_locations']).to eq(expected_location)
        end

        include_examples 'job data consistency'
      end
    end

    context 'when worker cannot be constantized' do
      let(:worker_class) { 'ActionMailer::MailDeliveryJob' }
      let(:expected_consistency) { :always }

      include_examples 'does not pass database locations'
    end

    context 'when worker class does not include ApplicationWorker' do
      let(:worker_class) { ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper }
      let(:expected_consistency) { :always }

      include_examples 'does not pass database locations'
    end

    context 'database wal location was already provided' do
      let(:old_location) { '0/D525E3A8' }
      let(:new_location) { 'AB/12345' }
      let(:wal_locations) { { Gitlab::Database::MAIN_DATABASE_NAME.to_sym => old_location } }
      let(:job) { { "job_id" => "a180b47c-3fd6-41b8-81e9-34da61c3400e", 'wal_locations' => wal_locations } }

      before do
        Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
          allow(lb).to receive(:primary_write_location).and_return(new_location)
          allow(lb).to receive(:database_replica_location).and_return(new_location)
        end
      end

      shared_examples_for 'does not set database location again' do |use_primary|
        before do
          allow(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_primary?).and_return(use_primary)
        end

        it 'does not set database locations again' do
          run_middleware

          expect(job['wal_locations']).to eq(wal_locations)
        end
      end

      context "when write was performed" do
        include_examples 'does not set database location again', true
      end

      context "when write was not performed" do
        include_examples 'does not set database location again', false
      end
    end

    context 'when worker data consistency is :always' do
      include_context 'data consistency worker class', :always, :load_balancing_for_test_data_consistency_worker

      include_examples 'does not pass database locations'
    end

    context 'when worker data consistency is :delayed' do
      include_examples 'mark data consistency location', :delayed
    end

    context 'when worker data consistency is :sticky' do
      include_examples 'mark data consistency location', :sticky
    end
  end
end
