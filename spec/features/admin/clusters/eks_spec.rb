# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance-level AWS EKS Cluster', :js do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
    gitlab_enable_admin_mode_sign_in(user)
  end

  context 'when user does not have a cluster and visits group clusters page' do
    before do
      visit admin_clusters_path

      click_link 'Connect with a certificate'
    end

    context 'when user creates a cluster on AWS EKS' do
      before do
        click_link 'Amazon EKS'
      end

      it 'user sees a form to create an EKS cluster' do
        expect(page).to have_content('Create new cluster on EKS')
      end
    end
  end
end
