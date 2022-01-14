# frozen_string_literal: true

# GroupsFinder
#
# Used to filter Groups by a set of params
#
# Arguments:
#   current_user - which user is requesting groups
#   params:
#     owned: boolean
#     parent: Group
#     all_available: boolean (defaults to true)
#     min_access_level: integer
#     search: string
#     exclude_group_ids: array of integers
#     include_parent_descendants: boolean (defaults to false) - includes descendant groups when
#                                 filtering by parent. The parent param must be present.
#
# Users with full private access can see all groups. The `owned` and `parent`
# params can be used to restrict the groups that are returned.
#
# Anonymous users will never return any `owned` groups. They will return all
# public groups instead, even if `all_available` is set to false.
class GroupsFinder < UnionFinder
  include CustomAttributesFilter

  def initialize(current_user = nil, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    items = all_groups.map do |item|
      item = by_parent(item)
      item = by_custom_attributes(item)
      item = exclude_group_ids(item)
      item = by_search(item)

      item
    end

    find_union(items, Group).with_route.order_id_desc
  end

  private

  attr_reader :current_user, :params

  def all_groups
    return [owned_groups] if params[:owned]
    return [groups_with_min_access_level] if min_access_level?
    return [Group.all] if current_user&.can_read_all_resources? && all_available?

    groups = []

    if current_user
      if Feature.enabled?(:use_traversal_ids_groups_finder, default_enabled: :yaml)
        groups << current_user.authorized_groups.self_and_ancestors
        groups << current_user.groups.self_and_descendants
      else
        groups << Gitlab::ObjectHierarchy.new(groups_for_ancestors, groups_for_descendants).all_objects
      end
    end

    groups << Group.unscoped.public_to_user(current_user) if include_public_groups?
    groups << Group.none if groups.empty?
    groups
  end

  def groups_for_ancestors
    current_user.authorized_groups
  end

  def groups_for_descendants
    current_user.groups
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def groups_with_min_access_level
    groups = current_user
      .groups
      .where('members.access_level >= ?', params[:min_access_level])

    if Feature.enabled?(:use_traversal_ids_groups_finder, default_enabled: :yaml)
      groups.self_and_descendants
    else
      Gitlab::ObjectHierarchy
        .new(groups)
        .base_and_descendants
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def exclude_group_ids(groups)
    return groups unless params[:exclude_group_ids]

    groups.id_not_in(params[:exclude_group_ids])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def by_parent(groups)
    return groups unless params[:parent]

    if include_parent_descendants?
      groups.id_in(params[:parent].descendants)
    else
      groups.where(parent: params[:parent])
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def by_search(groups)
    return groups unless params[:search].present?

    groups.search(params[:search], include_parents: params[:parent].blank?)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def owned_groups
    current_user&.owned_groups || Group.none
  end

  def include_public_groups?
    current_user.nil? || all_available?
  end

  def all_available?
    params.fetch(:all_available, true)
  end

  def include_parent_descendants?
    params.fetch(:include_parent_descendants, false)
  end

  def min_access_level?
    current_user && params[:min_access_level].present?
  end
end
