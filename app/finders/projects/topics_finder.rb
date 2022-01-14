# frozen_string_literal: true

# Used to filter project topics by a set of params
#
# Arguments:
#   params:
#     search: string
module Projects
  class TopicsFinder
    def initialize(params: {})
      @params = params
    end

    def execute
      topics = Projects::Topic.order_by_total_projects_count
      by_search(topics)
    end

    private

    attr_reader :current_user, :params

    def by_search(topics)
      return topics unless params[:search].present?

      topics.search(params[:search]).reorder_by_similarity(params[:search])
    end
  end
end
