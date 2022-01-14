# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Patch::DrawRoute do
  subject do
    Class.new do
      include Gitlab::Patch::DrawRoute

      def route_path(route_name)
        File.expand_path("../../../../#{route_name}", __dir__)
      end
    end.new
  end

  before do
    allow(subject).to receive(:instance_eval)
  end

  it 'evaluates CE only route' do
    subject.draw(:help)

    expect(subject).to have_received(:instance_eval)
      .with(File.read(subject.route_path('config/routes/help.rb')))
      .once

    expect(subject).to have_received(:instance_eval)
      .once
  end
end
