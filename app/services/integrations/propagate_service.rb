# frozen_string_literal: true

module Integrations
  class PropagateService
    BATCH_SIZE = 10_000

    def initialize(integration)
      @integration = integration
    end

    def propagate
      if integration.instance_level?
        update_inherited_integrations
        create_integration_for_groups_without_integration
        create_integration_for_projects_without_integration
      else
        update_inherited_descendant_integrations
        create_integration_for_groups_without_integration_belonging_to_group
        create_integration_for_projects_without_integration_belonging_to_group
      end
    end

    def self.propagate(integration)
      new(integration).propagate
    end

    private

    attr_reader :integration

    def create_integration_for_projects_without_integration
      propagate_integrations(
        Project.without_integration(integration),
        PropagateIntegrationProjectWorker
      )
    end

    def update_inherited_integrations
      propagate_integrations(
        Integration.by_type(integration.type).inherit_from_id(integration.id),
        PropagateIntegrationInheritWorker
      )
    end

    def update_inherited_descendant_integrations
      propagate_integrations(
        Integration.inherited_descendants_from_self_or_ancestors_from(integration),
        PropagateIntegrationInheritDescendantWorker
      )
    end

    def create_integration_for_groups_without_integration
      propagate_integrations(
        Group.without_integration(integration),
        PropagateIntegrationGroupWorker
      )
    end

    def create_integration_for_groups_without_integration_belonging_to_group
      propagate_integrations(
        integration.group.descendants.without_integration(integration),
        PropagateIntegrationGroupWorker
      )
    end

    def create_integration_for_projects_without_integration_belonging_to_group
      propagate_integrations(
        Project.without_integration(integration).in_namespace(integration.group.self_and_descendants),
        PropagateIntegrationProjectWorker
      )
    end

    def propagate_integrations(relation, worker_class)
      relation.each_batch(of: BATCH_SIZE) do |records|
        min_id, max_id = records.pick("MIN(#{relation.table_name}.id), MAX(#{relation.table_name}.id)")
        worker_class.perform_async(integration.id, min_id, max_id)
      end
    end
  end
end
