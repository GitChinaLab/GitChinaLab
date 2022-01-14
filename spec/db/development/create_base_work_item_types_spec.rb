# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create base work item types in development' do
  subject { load Rails.root.join('db', 'fixtures', 'development', '001_create_base_work_item_types.rb') }

  it_behaves_like 'work item base types importer'
end
