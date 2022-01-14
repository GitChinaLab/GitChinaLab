# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::GroupComponent do
  it_behaves_like 'Debian Distribution Component', :debian_group_component, :group, false
end
