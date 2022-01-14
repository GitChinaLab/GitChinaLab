# frozen_string_literal: true

module ProtectedBranches
  class UpdateService < ProtectedBranches::BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :update_protected_branch, protected_branch)

      old_merge_access_levels = protected_branch.merge_access_levels.map(&:clone)
      old_push_access_levels = protected_branch.push_access_levels.map(&:clone)

      if protected_branch.update(filtered_params)
        after_execute(protected_branch: protected_branch, old_merge_access_levels: old_merge_access_levels, old_push_access_levels: old_push_access_levels)
      end

      protected_branch
    end
  end
end

ProtectedBranches::UpdateService.prepend_mod_with('ProtectedBranches::UpdateService')
