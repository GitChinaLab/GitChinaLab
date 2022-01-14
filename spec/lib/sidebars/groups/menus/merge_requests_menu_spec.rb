# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::Menus::MergeRequestsMenu do
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) do
    build(:group, :private).tap do |g|
      g.add_owner(owner)
    end
  end

  let(:user) { owner }
  let(:context) { Sidebars::Groups::Context.new(current_user: user, container: group) }
  let(:menu) { described_class.new(context) }

  describe '#render?' do
    context 'when user can read merge requests' do
      it 'returns true' do
        expect(menu.render?).to eq true
      end
    end

    context 'when user cannot read merge requests' do
      let(:user) { nil }

      it 'returns false' do
        expect(menu.render?).to eq false
      end
    end
  end

  it_behaves_like 'pill_count formatted results' do
    let(:count_service) { ::Groups::MergeRequestsCountService }
  end
end
