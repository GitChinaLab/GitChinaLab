# frozen_string_literal: true

module Clusters
  class AgentAuthorizationsFinder
    def initialize(project)
      @project = project
    end

    def execute
      # closest, most-specific authorization for a given agent wins
      (project_authorizations + implicit_authorizations + group_authorizations)
        .uniq(&:agent_id)
    end

    private

    attr_reader :project

    def implicit_authorizations
      project.cluster_agents.map do |agent|
        Clusters::Agents::ImplicitAuthorization.new(agent: agent)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def project_authorizations
      ancestor_ids = project.group ? project.ancestors.select(:id) : project.namespace_id

      Clusters::Agents::ProjectAuthorization
        .where(project_id: project.id)
        .joins(agent: :project)
        .preload(agent: :project)
        .where(cluster_agents: { projects: { namespace_id: ancestor_ids } })
        .with_available_ci_access_fields(project)
        .to_a
    end

    def group_authorizations
      return [] unless project.group

      authorizations = Clusters::Agents::GroupAuthorization.arel_table

      ordered_ancestors_cte = Gitlab::SQL::CTE.new(
        :ordered_ancestors,
        project.group.self_and_ancestors(hierarchy_order: :asc).reselect(:id)
      )

      cte_join_sources = authorizations.join(ordered_ancestors_cte.table).on(
        authorizations[:group_id].eq(ordered_ancestors_cte.table[:id])
      ).join_sources

      Clusters::Agents::GroupAuthorization
        .with(ordered_ancestors_cte.to_arel)
        .joins(cte_join_sources)
        .joins(agent: :project)
        .where('projects.namespace_id IN (SELECT id FROM ordered_ancestors)')
        .with_available_ci_access_fields(project)
        .order(Arel.sql('agent_id, array_position(ARRAY(SELECT id FROM ordered_ancestors)::bigint[], agent_group_authorizations.group_id)'))
        .select('DISTINCT ON (agent_id) agent_group_authorizations.*')
        .preload(agent: :project)
        .to_a
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
