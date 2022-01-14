# frozen_string_literal: true

module BulkImports
  module Groups
    module Graphql
      module GetGroupQuery
        extend self

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!) {
            group(fullPath: $full_path) {
              name
              path
              full_path: fullPath
              description
              visibility
              emails_disabled: emailsDisabled
              lfs_enabled: lfsEnabled
              mentions_disabled: mentionsDisabled
              project_creation_level: projectCreationLevel
              request_access_enabled: requestAccessEnabled
              require_two_factor_authentication: requireTwoFactorAuthentication
              share_with_group_lock: shareWithGroupLock
              subgroup_creation_level: subgroupCreationLevel
              two_factor_grace_period: twoFactorGracePeriod
            }
          }
          GRAPHQL
        end

        def variables(context)
          { full_path: context.entity.source_full_path }
        end

        def base_path
          %w[data group]
        end

        def data_path
          base_path
        end

        def page_info_path
          base_path << 'page_info'
        end
      end
    end
  end
end
