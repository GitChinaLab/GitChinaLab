# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectAccessChangedService do
  describe '#execute' do
    it 'schedules the project IDs' do
      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to receive(:bulk_perform_and_wait)
        .with([[1], [2]])

      described_class.new([1, 2]).execute
    end

    it 'permits non-blocking operation' do
      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to receive(:bulk_perform_async)
        .with([[1], [2]])

      described_class.new([1, 2]).execute(blocking: false)
    end
  end
end
