# frozen_string_literal: true

class NamespaceSetting < ApplicationRecord
  include CascadingNamespaceSettingAttribute
  include Sanitizable

  cascading_attr :delayed_project_removal

  belongs_to :namespace, inverse_of: :namespace_settings

  validate :default_branch_name_content
  validate :allow_mfa_for_group
  validate :allow_resource_access_token_creation_for_group

  before_save :set_prevent_sharing_groups_outside_hierarchy, if: -> { user_cap_enabled? }
  after_save :disable_project_sharing!, if: -> { user_cap_enabled? }

  before_validation :normalize_default_branch_name

  enum jobs_to_be_done: { basics: 0, move_repository: 1, code_storage: 2, exploring: 3, ci: 4, other: 5 }, _suffix: true

  NAMESPACE_SETTINGS_PARAMS = [:default_branch_name, :delayed_project_removal,
                               :lock_delayed_project_removal, :resource_access_token_creation_allowed,
                               :prevent_sharing_groups_outside_hierarchy, :new_user_signups_cap,
                               :setup_for_company, :jobs_to_be_done].freeze

  self.primary_key = :namespace_id

  sanitizes! :default_branch_name

  def prevent_sharing_groups_outside_hierarchy
    return super if namespace.root?

    namespace.root_ancestor.prevent_sharing_groups_outside_hierarchy
  end

  private

  def normalize_default_branch_name
    self.default_branch_name = default_branch_name.presence
  end

  def default_branch_name_content
    return if default_branch_name.nil?

    if default_branch_name.blank?
      errors.add(:default_branch_name, "can not be an empty string")
    end
  end

  def allow_mfa_for_group
    if namespace&.subgroup? && allow_mfa_for_subgroups == false
      errors.add(:allow_mfa_for_subgroups, _('is not allowed since the group is not top-level group.'))
    end
  end

  def allow_resource_access_token_creation_for_group
    if namespace&.subgroup? && !resource_access_token_creation_allowed
      errors.add(:resource_access_token_creation_allowed, _('is not allowed since the group is not top-level group.'))
    end
  end

  def set_prevent_sharing_groups_outside_hierarchy
    self.prevent_sharing_groups_outside_hierarchy = true
  end

  def disable_project_sharing!
    namespace.update_attribute(:share_with_group_lock, true)
  end

  def user_cap_enabled?
    new_user_signups_cap.present? && namespace.root?
  end
end

NamespaceSetting.prepend_mod_with('NamespaceSetting')
