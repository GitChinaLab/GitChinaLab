# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::ServiceDiscovery do
  let(:load_balancer) do
    configuration = Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base)
    configuration.service_discovery[:record] = 'localhost'

    Gitlab::Database::LoadBalancing::LoadBalancer.new(configuration)
  end

  let(:service) do
    described_class.new(
      load_balancer,
      nameserver: 'localhost',
      port: 8600,
      record: 'foo'
    )
  end

  before do
    resource = double(:resource, address: IPAddr.new('127.0.0.1'))
    packet = double(:packet, answer: [resource])

    allow(Net::DNS::Resolver).to receive(:start)
      .with('localhost', Net::DNS::A)
      .and_return(packet)
  end

  describe '#initialize' do
    describe ':record_type' do
      subject do
        described_class.new(
          load_balancer,
          nameserver: 'localhost',
          port: 8600,
          record: 'foo',
          record_type: record_type
        )
      end

      context 'with a supported type' do
        let(:record_type) { 'SRV' }

        it { expect(subject.record_type).to eq Net::DNS::SRV }
      end

      context 'with an unsupported type' do
        let(:record_type) { 'AAAA' }

        it 'raises an argument error' do
          expect { subject }.to raise_error(ArgumentError, 'Unsupported record type: AAAA')
        end
      end
    end
  end

  describe '#start' do
    before do
      allow(service)
        .to receive(:loop)
        .and_yield
    end

    it 'starts service discovery in a new thread' do
      expect(Thread).to receive(:new).ordered.and_call_original # Thread starts

      expect(service).to receive(:perform_service_discovery).ordered.and_return(5)
      expect(service).to receive(:rand).ordered.and_return(2)
      expect(service).to receive(:sleep).ordered.with(7) # Sleep runs after thread starts

      service.start.join
    end
  end

  describe '#perform_service_discovery' do
    context 'without any failures' do
      it 'runs once' do
        expect(service)
          .to receive(:refresh_if_necessary).once

        expect(service).not_to receive(:sleep)

        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        service.perform_service_discovery
      end
    end

    context 'with failures' do
      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
        allow(service).to receive(:sleep)
      end

      let(:valid_retry_sleep_duration) { satisfy { |val| described_class::RETRY_DELAY_RANGE.include?(val) } }

      it 'retries service discovery when under the retry limit' do
        error = StandardError.new

        expect(service)
          .to receive(:refresh_if_necessary)
          .and_raise(error).exactly(described_class::MAX_DISCOVERY_RETRIES - 1).times.ordered

        expect(service)
          .to receive(:sleep).with(valid_retry_sleep_duration)
          .exactly(described_class::MAX_DISCOVERY_RETRIES - 1).times

        expect(service).to receive(:refresh_if_necessary).and_return(45).ordered

        expect(service.perform_service_discovery).to eq(45)
      end

      it 'does not retry service discovery after exceeding the limit' do
        error = StandardError.new

        expect(service)
          .to receive(:refresh_if_necessary)
          .and_raise(error).exactly(described_class::MAX_DISCOVERY_RETRIES).times

        expect(service)
          .to receive(:sleep).with(valid_retry_sleep_duration)
          .exactly(described_class::MAX_DISCOVERY_RETRIES).times

        service.perform_service_discovery
      end

      it 'reports exceptions to Sentry' do
        error = StandardError.new

        expect(service)
          .to receive(:refresh_if_necessary)
                .and_raise(error).exactly(described_class::MAX_DISCOVERY_RETRIES).times

        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
                .with(error).exactly(described_class::MAX_DISCOVERY_RETRIES).times

        service.perform_service_discovery
      end
    end
  end

  describe '#refresh_if_necessary' do
    let(:address_foo) { described_class::Address.new('foo') }
    let(:address_bar) { described_class::Address.new('bar') }

    context 'when a refresh is necessary' do
      before do
        allow(service)
          .to receive(:addresses_from_load_balancer)
          .and_return(%w[localhost])

        allow(service)
          .to receive(:addresses_from_dns)
          .and_return([10, [address_foo, address_bar]])
      end

      it 'refreshes the load balancer hosts' do
        expect(service)
          .to receive(:replace_hosts)
          .with([address_foo, address_bar])

        expect(service.refresh_if_necessary).to eq(10)
      end
    end

    context 'when a refresh is not necessary' do
      before do
        allow(service)
          .to receive(:addresses_from_load_balancer)
          .and_return(%w[localhost])

        allow(service)
          .to receive(:addresses_from_dns)
          .and_return([10, %w[localhost]])
      end

      it 'does not refresh the load balancer hosts' do
        expect(service)
          .not_to receive(:replace_hosts)

        expect(service.refresh_if_necessary).to eq(10)
      end
    end
  end

  describe '#replace_hosts' do
    let(:address_foo) { described_class::Address.new('foo') }
    let(:address_bar) { described_class::Address.new('bar') }

    let(:load_balancer) do
      Gitlab::Database::LoadBalancing::LoadBalancer.new(
        Gitlab::Database::LoadBalancing::Configuration
          .new(ActiveRecord::Base, [address_foo])
      )
    end

    before do
      allow(service)
        .to receive(:load_balancer)
        .and_return(load_balancer)
    end

    it 'replaces the hosts of the load balancer' do
      service.replace_hosts([address_bar])

      expect(load_balancer.host_list.host_names_and_ports).to eq([['bar', nil]])
    end

    it 'disconnects the old connections' do
      host = load_balancer.host_list.hosts.first

      allow(service)
        .to receive(:disconnect_timeout)
        .and_return(2)

      expect(host)
        .to receive(:disconnect!)
        .with(timeout: 2)

      service.replace_hosts([address_bar])
    end
  end

  describe '#addresses_from_dns' do
    let(:service) do
      described_class.new(
        load_balancer,
        nameserver: 'localhost',
        port: 8600,
        record: 'foo',
        record_type: record_type
      )
    end

    let(:packet) { double(:packet, answer: [res1, res2]) }

    before do
      allow(service.resolver)
        .to receive(:search)
        .with('foo', described_class::RECORD_TYPES[record_type])
        .and_return(packet)
    end

    context 'with an A record' do
      let(:record_type) { 'A' }

      let(:res1) { double(:resource, address: IPAddr.new('255.255.255.0'), ttl: 90) }
      let(:res2) { double(:resource, address: IPAddr.new('127.0.0.1'), ttl: 90) }

      it 'returns a TTL and ordered list of IP addresses' do
        addresses = [
          described_class::Address.new('127.0.0.1'),
          described_class::Address.new('255.255.255.0')
        ]

        expect(service.addresses_from_dns).to eq([90, addresses])
      end
    end

    context 'with an SRV record' do
      let(:record_type) { 'SRV' }

      let(:res1) { double(:resource, host: 'foo1.service.consul.', port: 5432, weight: 1, priority: 1, ttl: 90) }
      let(:res2) { double(:resource, host: 'foo2.service.consul.', port: 5433, weight: 1, priority: 1, ttl: 90) }
      let(:res3) { double(:resource, host: 'foo3.service.consul.', port: 5434, weight: 1, priority: 1, ttl: 90) }
      let(:packet) { double(:packet, answer: [res1, res2, res3], additional: []) }

      before do
        expect_next_instance_of(Gitlab::Database::LoadBalancing::SrvResolver) do |resolver|
          allow(resolver).to receive(:address_for).with('foo1.service.consul.').and_return(IPAddr.new('255.255.255.0'))
          allow(resolver).to receive(:address_for).with('foo2.service.consul.').and_return(IPAddr.new('127.0.0.1'))
          allow(resolver).to receive(:address_for).with('foo3.service.consul.').and_return(nil)
        end
      end

      it 'returns a TTL and ordered list of hosts' do
        addresses = [
          described_class::Address.new('127.0.0.1', 5433),
          described_class::Address.new('255.255.255.0', 5432)
        ]

        expect(service.addresses_from_dns).to eq([90, addresses])
      end
    end

    context 'when the resolver returns an empty response' do
      let(:packet) { double(:packet, answer: []) }

      let(:record_type) { 'A' }

      it 'raises EmptyDnsResponse' do
        expect { service.addresses_from_dns }.to raise_error(Gitlab::Database::LoadBalancing::ServiceDiscovery::EmptyDnsResponse)
      end
    end
  end

  describe '#new_wait_time_for' do
    it 'returns the DNS TTL if greater than the default interval' do
      res = double(:resource, ttl: 90)

      expect(service.new_wait_time_for([res])).to eq(90)
    end

    it 'returns the default interval if greater than the DNS TTL' do
      res = double(:resource, ttl: 10)

      expect(service.new_wait_time_for([res])).to eq(60)
    end

    it 'returns the default interval if no resources are given' do
      expect(service.new_wait_time_for([])).to eq(60)
    end
  end

  describe '#addresses_from_load_balancer' do
    let(:load_balancer) do
      Gitlab::Database::LoadBalancing::LoadBalancer.new(
        Gitlab::Database::LoadBalancing::Configuration
          .new(ActiveRecord::Base, %w[b a])
      )
    end

    it 'returns the ordered host names of the load balancer' do
      addresses = [
        described_class::Address.new('a'),
        described_class::Address.new('b')
      ]

      expect(service.addresses_from_load_balancer).to eq(addresses)
    end
  end
end
