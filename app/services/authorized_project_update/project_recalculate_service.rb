# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculateService
    # Service for refreshing all the authorizations to a particular project.
    include Gitlab::Utils::StrongMemoize
    BATCH_SIZE = 1000

    def initialize(project)
      @project = project
    end

    def execute
      refresh_authorizations if needs_refresh?
      ServiceResponse.success
    end

    private

    attr_reader :project

    def needs_refresh?
      user_ids_to_remove.any? ||
        authorizations_to_create.any?
    end

    def current_authorizations
      strong_memoize(:current_authorizations) do
        apply_scopes(project.project_authorizations)
          .pluck(:user_id, :access_level) # rubocop: disable CodeReuse/ActiveRecord
      end
    end

    def fresh_authorizations
      strong_memoize(:fresh_authorizations) do
        result = []

        effective_access_levels
          .each_batch(of: BATCH_SIZE, column: :user_id) do |member_batch|
            result += member_batch.pluck(:user_id, 'MAX(access_level)') # rubocop: disable CodeReuse/ActiveRecord
          end

        result
      end
    end

    def user_ids_to_remove
      strong_memoize(:user_ids_to_remove) do
        (current_authorizations - fresh_authorizations)
          .map {|user_id, _| user_id }
      end
    end

    def authorizations_to_create
      strong_memoize(:authorizations_to_create) do
        (fresh_authorizations - current_authorizations).map do |user_id, access_level|
          {
            user_id: user_id,
            access_level: access_level,
            project_id: project.id
          }
        end
      end
    end

    def refresh_authorizations
      project.remove_project_authorizations(user_ids_to_remove) if user_ids_to_remove.any?
      ProjectAuthorization.insert_all_in_batches(authorizations_to_create) if authorizations_to_create.any?
    end

    def apply_scopes(project_authorizations)
      project_authorizations
    end

    def effective_access_levels
      Projects::Members::EffectiveAccessLevelFinder.new(project).execute
    end
  end
end
