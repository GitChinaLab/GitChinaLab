# frozen_string_literal: true

require 'securerandom'
require 'google/apis/compute_v1'
require 'google/apis/container_v1'
require 'google/apis/container_v1beta1'
require 'google/apis/cloudbilling_v1'
require 'google/apis/cloudresourcemanager_v1'
require 'google/apis/iam_v1'

module GoogleApi
  module CloudPlatform
    class Client < GoogleApi::Auth
      SCOPE = 'https://www.googleapis.com/auth/cloud-platform'
      LEAST_TOKEN_LIFE_TIME = 10.minutes
      CLUSTER_MASTER_AUTH_USERNAME = 'admin'
      CLUSTER_IPV4_CIDR_BLOCK = '/16'
      CLUSTER_OAUTH_SCOPES = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring"
      ].freeze

      class << self
        def session_key_for_token
          :cloud_platform_access_token
        end

        def session_key_for_expires_at
          :cloud_platform_expires_at
        end

        def new_session_key_for_redirect_uri
          SecureRandom.hex.tap do |state|
            yield session_key_for_redirect_uri(state)
          end
        end

        def session_key_for_redirect_uri(state)
          "cloud_platform_second_redirect_uri_#{state}"
        end
      end

      def scope
        SCOPE
      end

      def validate_token(expires_at)
        return false unless access_token
        return false unless expires_at

        # Making sure that the token will have been still alive during the cluster creation.
        return false if token_life_time(expires_at) < LEAST_TOKEN_LIFE_TIME

        true
      end

      def projects_zones_clusters_get(project_id, zone, cluster_id)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        service.get_zone_cluster(project_id, zone, cluster_id, options: user_agent_header)
      end

      def projects_zones_clusters_create(project_id, zone, cluster_name, cluster_size, machine_type:, legacy_abac:, enable_addons: [])
        service = Google::Apis::ContainerV1beta1::ContainerService.new
        service.authorization = access_token

        cluster_options = make_cluster_options(cluster_name, cluster_size, machine_type, legacy_abac, enable_addons)

        request_body = Google::Apis::ContainerV1beta1::CreateClusterRequest.new(**cluster_options)

        service.create_cluster(project_id, zone, request_body, options: user_agent_header)
      end

      def projects_zones_operations(project_id, zone, operation_id)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        service.get_zone_operation(project_id, zone, operation_id, options: user_agent_header)
      end

      def parse_operation_id(self_link)
        m = self_link.match(%r{projects/.*/zones/.*/operations/(.*)})
        m[1] if m
      end

      def list_projects
        result = []

        service = Google::Apis::CloudresourcemanagerV1::CloudResourceManagerService.new
        service.authorization = access_token

        response = service.fetch_all(items: :projects) do |token|
          service.list_projects
        end

        # Google API results are paged by default, so we need to iterate through
        response.each do |project|
          result.append(project)
        end

        result
      end

      def create_service_account(gcp_project_id, display_name, description)
        name = "projects/#{gcp_project_id}"

        # initialize google iam service
        service = Google::Apis::IamV1::IamService.new
        service.authorization = access_token

        # generate account id
        random_account_id = "gitlab-" + SecureRandom.hex(11)

        body_params = { account_id: random_account_id,
                        service_account: { display_name: display_name,
                                           description: description } }

        request_body = Google::Apis::IamV1::CreateServiceAccountRequest.new(**body_params)
        service.create_service_account(name, request_body)
      end

      def create_service_account_key(gcp_project_id, service_account_id)
        service = Google::Apis::IamV1::IamService.new
        service.authorization = access_token

        name = "projects/#{gcp_project_id}/serviceAccounts/#{service_account_id}"
        request_body = Google::Apis::IamV1::CreateServiceAccountKeyRequest.new
        service.create_service_account_key(name, request_body)
      end

      private

      def make_cluster_options(cluster_name, cluster_size, machine_type, legacy_abac, enable_addons)
        {
          cluster: {
            name: cluster_name,
            initial_node_count: cluster_size,
            node_config: {
              machine_type: machine_type,
              oauth_scopes: CLUSTER_OAUTH_SCOPES
            },
            master_auth: {
              client_certificate_config: {
                issue_client_certificate: true
              }
            },
            legacy_abac: {
              enabled: legacy_abac
            },
            ip_allocation_policy: {
              use_ip_aliases: true,
              cluster_ipv4_cidr_block: CLUSTER_IPV4_CIDR_BLOCK
            },
            addons_config: make_addons_config(enable_addons)
          }
        }
      end

      def make_addons_config(enable_addons)
        enable_addons.each_with_object({}) do |addon, hash|
          hash[addon] = { disabled: false }
        end
      end

      def token_life_time(expires_at)
        DateTime.strptime(expires_at, '%s').to_time.utc - Time.now.utc
      end

      def user_agent_header
        Google::Apis::RequestOptions.new.tap do |options|
          options.header = { 'User-Agent': "GitLab/#{Gitlab::VERSION.match('(\d+\.\d+)').captures.first} (GPN:GitLab;)" }
        end
      end
    end
  end
end
