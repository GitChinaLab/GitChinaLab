# frozen_string_literal: true

RSpec.shared_examples 'a cascading setting' do
  context 'when setting is enforced by an ancestor group' do
    before do
      visit group_path

      page.within form_group_selector do
        find(setting_field_selector).check
        find('[data-testid="enforce-for-all-subgroups-checkbox"]').check
      end

      click_save_button
    end

    shared_examples 'subgroup settings are disabled' do
      it 'disables setting in subgroups' do
        visit subgroup_path

        expect(find("#{setting_field_selector}[disabled]")).to be_checked
      end
    end

    include_examples 'subgroup settings are disabled'

    context 'when use_traversal_ids_for_ancestors is disabled' do
      before do
        stub_feature_flags(use_traversal_ids_for_ancestors: false)
      end

      include_examples 'subgroup settings are disabled'
    end

    it 'does not show enforcement checkbox in subgroups' do
      visit subgroup_path

      expect(page).not_to have_selector '[data-testid="enforce-for-all-subgroups-checkbox"]'
    end

    it 'displays lock icon with popover', :js do
      visit subgroup_path

      page.within form_group_selector do
        find('[data-testid="cascading-settings-lock-icon"]').click
      end

      page.within '[data-testid="cascading-settings-lock-popover"]' do
        expect(page).to have_text 'This setting has been enforced by an owner of Foo bar.'
        expect(page).to have_link 'Foo bar', href: setting_path
      end
    end
  end
end
