# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ServiceDesk do
  before do
    allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
    allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(true)
  end

  describe 'enabled?' do
    let_it_be(:project) { create(:project) }

    subject { described_class.enabled?(project: project) }

    it { is_expected.to be_truthy }

    context 'when service desk is not supported' do
      before do
        allow(described_class).to receive(:supported?).and_return(false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when service desk is disabled for project' do
      before do
        project.update!(service_desk_enabled: false)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe 'supported?' do
    subject { described_class.supported? }

    it { is_expected.to be_truthy }

    context 'when incoming emails are disabled' do
      before do
        allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when email key is not supported' do
      before do
        allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?).and_return(false)
      end

      it { is_expected.to be_falsy }
    end
  end
end
