# frozen_string_literal: true

module BulkImports
  module Clients
    class HTTP
      include Gitlab::Utils::StrongMemoize

      API_VERSION = 'v4'
      DEFAULT_PAGE = 1
      DEFAULT_PER_PAGE = 30

      def initialize(url:, token:, page: DEFAULT_PAGE, per_page: DEFAULT_PER_PAGE, api_version: API_VERSION)
        @url = url
        @token = token&.strip
        @page = page
        @per_page = per_page
        @api_version = api_version
        @compatible_instance_version = false
      end

      def get(resource, query = {})
        request(:get, resource, query: query.reverse_merge(request_query))
      end

      def post(resource, body = {})
        request(:post, resource, body: body)
      end

      def head(resource)
        request(:head, resource)
      end

      def stream(resource, &block)
        request(:get, resource, stream_body: true, &block)
      end

      def each_page(method, resource, query = {}, &block)
        return to_enum(__method__, method, resource, query) unless block_given?

        next_page = @page

        while next_page
          @page = next_page.to_i

          response = self.public_send(method, resource, query) # rubocop: disable GitlabSecurity/PublicSend
          collection = response.parsed_response
          next_page = response.headers['x-next-page'].presence

          yield collection
        end
      end

      def resource_url(resource)
        Gitlab::Utils.append_path(api_url, resource)
      end

      def instance_version
        strong_memoize(:instance_version) do
          response = with_error_handling do
            Gitlab::HTTP.get(resource_url(:version), default_options)
          end

          Gitlab::VersionInfo.parse(response.parsed_response['version'])
        end
      end

      def compatible_for_project_migration?
        instance_version >= BulkImport.min_gl_version_for_project_migration
      end

      private

      def validate_instance_version!
        return if @compatible_instance_version

        if instance_version.major < BulkImport::MIN_MAJOR_VERSION
          raise ::BulkImports::Error.unsupported_gitlab_version
        else
          @compatible_instance_version = true
        end
      end

      # rubocop:disable GitlabSecurity/PublicSend
      def request(method, resource, options = {}, &block)
        validate_instance_version!

        with_error_handling do
          Gitlab::HTTP.public_send(
            method,
            resource_url(resource),
            request_options(options),
            &block
          )
        end
      end
      # rubocop:enable GitlabSecurity/PublicSend

      def request_options(options)
        default_options.merge(options)
      end

      def default_options
        {
          headers: request_headers,
          follow_redirects: false
        }
      end

      def request_query
        {
          page: @page,
          per_page: @per_page
        }
      end

      def request_headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@token}"
        }
      end

      def with_error_handling
        response = yield

        raise ::BulkImports::NetworkError.new("Unsuccessful response #{response.code} from #{response.request.path.path}", response: response) unless response.success?

        response
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        raise ::BulkImports::NetworkError, e
      end

      def api_url
        Gitlab::Utils.append_path(@url, "/api/#{@api_version}")
      end
    end
  end
end
