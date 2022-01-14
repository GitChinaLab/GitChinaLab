# frozen_string_literal: true

class RunnerSetupController < ApplicationController
  feature_category :runner

  def platforms
    render json: Gitlab::Ci::RunnerInstructions::OS.merge(Gitlab::Ci::RunnerInstructions::OTHER_ENVIRONMENTS)
  end
end
