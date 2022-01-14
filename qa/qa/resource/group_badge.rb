# frozen_string_literal: true

module QA
  module Resource
    class GroupBadge < Base
      attributes :id,
                 :name,
                 :link_url,
                 :image_url,
                 :group

      # API get path
      #
      # @return [String]
      def api_get_path
        "/groups/#{CGI.escape(group.full_path)}/badges/#{id}"
      end

      # API post path
      #
      # @return [String]
      def api_post_path
        "/groups/#{CGI.escape(group.full_path)}/badges"
      end

      # Params for label creation
      #
      # @return [Hash]
      def api_post_body
        {
          link_url: link_url,
          image_url: image_url
        }
      end

      # Override base method as this particular resource does not expose a web_url property
      #
      # @param [Hash] resource
      # @return [String]
      def resource_web_url(_resource); end

      # Object comparison
      #
      # @param [QA::Resource::GroupBadge] other
      # @return [Boolean]
      def ==(other)
        other.is_a?(GroupBadge) && comparable_badge == other.comparable_badge
      end

      # Override inspect for a better rspec failure diff output
      #
      # @return [String]
      def inspect
        JSON.pretty_generate(comparable_badge)
      end

      protected

      # Return subset of fields for comparing badges
      #
      # @return [Hash]
      def comparable_badge
        reload! unless api_response

        api_response.slice(
          :name,
          :link_url,
          :image_url
        )
      end
    end
  end
end
