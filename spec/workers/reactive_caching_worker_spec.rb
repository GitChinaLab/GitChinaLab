# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveCachingWorker do
  it_behaves_like 'reactive cacheable worker'
end
