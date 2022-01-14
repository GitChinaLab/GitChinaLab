# frozen_string_literal: true

# Mixin for all resolver classes for type `Types::GroupType.connection_type`.
module ResolvesGroups
  extend ActiveSupport::Concern
  include LooksAhead

  def resolve_with_lookahead(**args)
    apply_lookahead(resolve_groups(**args))
  end

  private

  # The resolver should implement this method.
  def resolve_groups(**args)
    raise NotImplementedError
  end

  def preloads
    {
      contacts: [:contacts],
      container_repositories_count: [:container_repositories],
      custom_emoji: [:custom_emoji],
      full_path: [:route],
      organizations: [:organizations],
      path: [:route],
      dependency_proxy_blob_count: [:dependency_proxy_blobs],
      dependency_proxy_blobs: [:dependency_proxy_blobs],
      dependency_proxy_image_count: [:dependency_proxy_manifests],
      dependency_proxy_image_ttl_policy: [:dependency_proxy_image_ttl_policy],
      dependency_proxy_setting: [:dependency_proxy_setting]
    }
  end
end
