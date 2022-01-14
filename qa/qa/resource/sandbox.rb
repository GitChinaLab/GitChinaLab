# frozen_string_literal: true

module QA
  module Resource
    ##
    # Ensure we're in our sandbox namespace, either by navigating to it or by
    # creating it if it doesn't yet exist.
    #
    class Sandbox < GroupBase
      class << self
        # Force top level group creation via UI if test is executed on dot_com environment
        def fabricate!(*args, &prepare_block)
          return fabricate_via_browser_ui!(*args, &prepare_block) if Specs::Helpers::ContextSelector.dot_com?

          fabricate_via_api!(*args, &prepare_block)
        rescue NotImplementedError
          fabricate_via_browser_ui!(*args, &prepare_block)
        end
      end

      def initialize
        @path = Runtime::Namespace.sandbox_name
      end

      alias_method :full_path, :path

      def fabricate!
        Flow::Login.sign_in_unless_signed_in

        Page::Main::Menu.perform(&:go_to_groups)

        Page::Dashboard::Groups.perform do |groups_page|
          if groups_page.has_group?(path)
            groups_page.click_group(path)
          else
            groups_page.click_new_group

            Page::Group::New.perform do |group|
              group.click_create_group
              group.set_path(path)
              group.set_visibility('Public')
              group.create
            end

            @id = Page::Group::Show.perform(&:group_id)
          end
        end
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super

        # If the group was just created the runners token might not be
        # available via the API immediately.
        Support::Retrier.retry_on_exception(sleep_interval: 5) do
          resource = resource_web_url(api_get)
          populate(:runners_token)
          resource
        end
      end

      def api_get_path
        "/groups/#{path}"
      end

      def api_post_body
        {
          path: path,
          name: path,
          visibility: 'public',
          avatar: avatar
        }
      end

      def update_group_setting(group_setting:, value:)
        response = put(Runtime::API::Request.new(api_client, api_put_path).url, { "#{group_setting}": value })
        return if response.code == HTTP_STATUS_OK

        raise(
          ResourceUpdateFailedError,
          "Could not update #{group_setting} to #{value}. Request returned (#{response.code}): `#{response}`."
        )
      end
    end
  end
end
