# frozen_string_literal: true

module API
  class Topics < ::API::Base
    include PaginationParams

    feature_category :projects

    desc 'Get topics' do
      detail 'This feature was introduced in GitLab 14.5.'
      success Entities::Projects::Topic
    end
    params do
      optional :search, type: String, desc: 'Return list of topics matching the search criteria'
      use :pagination
    end
    get 'topics' do
      topics = ::Projects::TopicsFinder.new(params: declared_params(include_missing: false)).execute

      present paginate(topics), with: Entities::Projects::Topic
    end

    desc 'Get topic' do
      detail 'This feature was introduced in GitLab 14.5.'
      success Entities::Projects::Topic
    end
    params do
      requires :id, type: Integer, desc: 'ID of project topic'
    end
    get 'topics/:id' do
      topic = ::Projects::Topic.find(params[:id])

      present topic, with: Entities::Projects::Topic
    end

    desc 'Create a topic' do
      detail 'This feature was introduced in GitLab 14.5.'
      success Entities::Projects::Topic
    end
    params do
      requires :name, type: String, desc: 'Name'
      optional :description, type: String, desc: 'Description'
      optional :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'Avatar image for topic'
    end
    post 'topics' do
      authenticated_as_admin!

      topic = ::Projects::Topic.new(declared_params(include_missing: false))

      if topic.save
        present topic, with: Entities::Projects::Topic
      else
        render_validation_error!(topic)
      end
    end

    desc 'Update a topic' do
      detail 'This feature was introduced in GitLab 14.5.'
      success Entities::Projects::Topic
    end
    params do
      requires :id, type: Integer, desc: 'ID of project topic'
      optional :name, type: String, desc: 'Name'
      optional :description, type: String, desc: 'Description'
      optional :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'Avatar image for topic'
    end
    put 'topics/:id' do
      authenticated_as_admin!

      topic = ::Projects::Topic.find(params[:id])

      topic.remove_avatar! if params.key?(:avatar) && params[:avatar].nil?

      if topic.update(declared_params(include_missing: false))
        present topic, with: Entities::Projects::Topic
      else
        render_validation_error!(topic)
      end
    end
  end
end
