# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class EnsureEnvironments < Chain::Base
          def perform!
            return unless pipeline.create_deployment_in_separate_transaction?

            pipeline.stages.map(&:statuses).flatten.each(&method(:ensure_environment))
          end

          def break?
            false
          end

          private

          def ensure_environment(build)
            return unless build.instance_of?(::Ci::Build) && build.has_environment?

            environment = ::Gitlab::Ci::Pipeline::Seed::Environment.new(build).to_resource

            if environment.persisted?
              build.persisted_environment = environment
              build.assign_attributes(metadata_attributes: { expanded_environment_name: environment.name })
            else
              build.assign_attributes(status: :failed, failure_reason: :environment_creation_failure)
            end
          end
        end
      end
    end
  end
end
