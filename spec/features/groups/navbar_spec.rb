# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group navbar' do
  include NavbarStructureHelper
  include WikiHelpers

  include_context 'group navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    insert_package_nav(_('Kubernetes'))

    stub_feature_flags(customer_relations: false)
    stub_config(dependency_proxy: { enabled: false })
    stub_config(registry: { enabled: false })
    stub_group_wikis(false)
    group.add_maintainer(user)
    sign_in(user)
  end

  it_behaves_like 'verified navigation bar' do
    before do
      visit group_path(group)
    end
  end

  context 'when container registry is available' do
    before do
      stub_config(registry: { enabled: true })

      insert_container_nav

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when customer_relations feature flag is enabled' do
    before do
      stub_feature_flags(customer_relations: true)

      if Gitlab.ee?
        insert_customer_relations_nav(_('Analytics'))
      else
        insert_customer_relations_nav(_('Packages & Registries'))
      end

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when dependency proxy is available' do
    before do
      stub_config(dependency_proxy: { enabled: true })

      insert_dependency_proxy_nav

      visit group_path(group)
    end

    it_behaves_like 'verified navigation bar'
  end
end
