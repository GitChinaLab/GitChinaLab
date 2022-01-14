# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GenerateDistributionKeyService do
  let(:params) { {} }

  subject { described_class.new(params: params) }

  let(:response) { subject.execute }

  it 'returns an Hash', :aggregate_failures do
    expect(GPGME::Ctx).to receive(:new).with(armor: true, offline: true).and_call_original
    expect(User).to receive(:random_password).with(no_args).and_call_original

    expect(response).to be_a Hash
    expect(response.keys).to contain_exactly(:private_key, :public_key, :fingerprint, :passphrase)
    expect(response[:private_key]).to start_with('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(response[:public_key]).to start_with('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(response[:fingerprint].length).to eq(40)
    expect(response[:passphrase].length).to be > 10
  end
end
