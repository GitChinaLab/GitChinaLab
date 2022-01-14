# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Pipeline
          include Gitlab::Utils::StrongMemoize

          def initialize(context, stages_attributes)
            @context = context
            @stages_attributes = stages_attributes
          end

          def errors
            stage_seeds.flat_map(&:errors).compact.presence
          end

          def stages
            stage_seeds.map(&:to_resource)
          end

          def size
            stage_seeds.sum(&:size)
          end

          def deployments_count
            stage_seeds.sum do |stage_seed|
              stage_seed.seeds.count do |build_seed|
                build_seed.attributes[:environment].present?
              end
            end
          end

          private

          def stage_seeds
            strong_memoize(:stage_seeds) do
              seeds = @stages_attributes.inject([]) do |previous_stages, attributes|
                seed = Gitlab::Ci::Pipeline::Seed::Stage.new(@context, attributes, previous_stages)
                previous_stages + [seed]
              end

              seeds.select(&:included?)
            end
          end
        end
      end
    end
  end
end
