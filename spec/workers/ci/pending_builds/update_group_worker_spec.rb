# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PendingBuilds::UpdateGroupWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when a group is not provided' do
      it 'does not call the service' do
        expect(::Ci::UpdatePendingBuildService).not_to receive(:new)
      end
    end

    context 'when everything is ok' do
      let(:group) { create(:group) }
      let(:update_pending_build_service) { instance_double(::Ci::UpdatePendingBuildService) }
      let(:update_params) { { "namespace_id" => group.id } }

      it 'calls the service' do
        expect(::Ci::UpdatePendingBuildService).to receive(:new).with(group, update_params).and_return(update_pending_build_service)
        expect(update_pending_build_service).to receive(:execute)

        worker.perform(group.id, update_params)
      end

      include_examples 'an idempotent worker' do
        let(:pending_build) { create(:ci_pending_build) }
        let(:update_params) { { "namespace_id" => pending_build.namespace_id } }
        let(:job_args) { [pending_build.namespace_id, update_params] }

        it 'updates the pending builds' do
          subject

          expect(pending_build.reload.namespace_id).to eq(update_params["namespace_id"])
        end
      end
    end
  end
end
