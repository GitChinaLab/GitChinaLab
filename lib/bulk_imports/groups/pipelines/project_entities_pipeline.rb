# frozen_string_literal: true

module BulkImports
  module Groups
    module Pipelines
      class ProjectEntitiesPipeline
        include Pipeline

        extractor Common::Extractors::GraphqlExtractor, query: Graphql::GetProjectsQuery
        transformer Common::Transformers::ProhibitedAttributesTransformer

        def transform(context, data)
          {
            source_type: :project_entity,
            source_full_path: data['full_path'],
            destination_name: data['name'],
            destination_namespace: context.entity.group.full_path,
            parent_id: context.entity.id
          }
        end

        def load(context, data)
          context.bulk_import.entities.create!(data)
        end
      end
    end
  end
end
