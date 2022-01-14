# frozen_string_literal: true

module Users
  class GroupCallout < ApplicationRecord
    include Users::Calloutable

    self.table_name = 'user_group_callouts'

    belongs_to :group

    enum feature_name: {
      invite_members_banner: 1
    }

    validates :group, presence: true
    validates :feature_name,
              presence: true,
              uniqueness: { scope: [:user_id, :group_id] },
              inclusion: { in: GroupCallout.feature_names.keys }

    def source_feature_name
      "#{feature_name}_#{group_id}"
    end
  end
end
