# frozen_string_literal: true

module Sidebars
  module Groups
    module Menus
      class CustomerRelationsMenu < ::Sidebars::Menu
        override :configure_menu_items
        def configure_menu_items
          add_item(contacts_menu_item) if can_read_contact?
          add_item(organizations_menu_item) if can_read_organization?

          true
        end

        override :title
        def title
          _('Customer relations')
        end

        override :sprite_icon
        def sprite_icon
          'users'
        end

        override :render?
        def render?
          can_read_contact? || can_read_organization?
        end

        private

        def contacts_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Contacts'),
            link: group_crm_contacts_path(context.group),
            active_routes: { path: 'groups/crm#contacts' },
            item_id: :crm_contacts
          )
        end

        def organizations_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Organizations'),
            link: group_crm_organizations_path(context.group),
            active_routes: { path: 'groups/crm#organizations' },
            item_id: :crm_organizations
          )
        end

        def can_read_contact?
          can?(context.current_user, :read_crm_contact, context.group)
        end

        def can_read_organization?
          can?(context.current_user, :read_crm_organization, context.group)
        end
      end
    end
  end
end
