# frozen_string_literal: true

module QA
  module Resource
    # Base class for group classes Resource::Sandbox and Resource::Group
    #
    class GroupBase < Base
      include Members

      attr_accessor :path, :avatar

      attributes :id,
                 :runners_token,
                 :name,
                 :full_path

      # Get group projects
      #
      # @return [Array<QA::Resource::Project>]
      def projects
        parse_body(api_get_from("#{api_get_path}/projects")).map do |project|
          Project.init do |resource|
            resource.api_client = api_client
            resource.group = self
            resource.id = project[:id]
            resource.name = project[:name]
            resource.description = project[:description]
            resource.path_with_namespace = project[:path_with_namespace]
          end
        end
      end

      # Get group labels
      #
      # @return [Array<QA::Resource::GroupLabel>]
      def labels
        parse_body(api_get_from("#{api_get_path}/labels")).map do |label|
          GroupLabel.init do |resource|
            resource.api_client = api_client
            resource.group = self
            resource.id = label[:id]
            resource.title = label[:name]
            resource.description = label[:description]
            resource.color = label[:color]
          end
        end
      end

      # Get group milestones
      #
      # @return [Array<QA::Resource::GroupMilestone>]
      def milestones
        parse_body(api_get_from("#{api_get_path}/milestones")).map do |milestone|
          GroupMilestone.init do |resource|
            resource.api_client = api_client
            resource.group = self
            resource.id = milestone[:id]
            resource.iid = milestone[:iid]
            resource.title = milestone[:title]
            resource.description = milestone[:description]
          end
        end
      end

      # Get group badges
      #
      # @return [Array<QA::Resource::GroupBadge>]
      def badges
        parse_body(api_get_from("#{api_get_path}/badges")).map do |badge|
          GroupBadge.init do |resource|
            resource.api_client = api_client
            resource.group = self
            resource.id = badge[:id]
            resource.name = badge[:name]
            resource.link_url = badge[:link_url]
            resource.image_url = badge[:image_url]
          end
        end
      end

      # Get group members
      #
      # @return [Array<QA::Resource::User>]
      def members
        parse_body(api_get_from("#{api_get_path}/members")).map do |member|
          User.init do |resource|
            resource.api_client = api_client
            resource.id = member[:id]
            resource.name = member[:name]
            resource.username = member[:username]
            resource.email = member[:email]
            resource.access_level = member[:access_level]
          end
        end
      end

      # API get path
      #
      # @return [String]
      def api_get_path
        raise NotImplementedError
      end

      # API post path
      #
      # @return [String]
      def api_post_path
        '/groups'
      end

      # API put path
      #
      # @return [String]
      def api_put_path
        "/groups/#{id}"
      end

      # API delete path
      #
      # @return [String]
      def api_delete_path
        "/groups/#{id}"
      end

      # Object comparison
      #
      # @param [QA::Resource::GroupBase] other
      # @return [Boolean]
      def ==(other)
        other.is_a?(GroupBase) && comparable_group == other.comparable_group
      end

      # Override inspect for a better rspec failure diff output
      #
      # @return [String]
      def inspect
        JSON.pretty_generate(comparable_group)
      end

      protected

      # Return subset of fields for comparing groups
      #
      # @return [Hash]
      def comparable_group
        reload! if api_response.nil?

        api_resource.slice(
          :name,
          :path,
          :description,
          :emails_disabled,
          :lfs_enabled,
          :mentions_disabled,
          :project_creation_level,
          :request_access_enabled,
          :require_two_factor_authentication,
          :share_with_group_lock,
          :subgroup_creation_level,
          :two_factor_grace_perion
          # TODO: Add back visibility comparison once https://gitlab.com/gitlab-org/gitlab/-/issues/331252 is fixed
          # :visibility
        )
      end
    end
  end
end

QA::Resource::GroupBase.prepend_mod_with('Resource::GroupBase', namespace: QA)
