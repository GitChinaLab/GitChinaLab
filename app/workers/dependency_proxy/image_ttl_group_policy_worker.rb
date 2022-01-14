# frozen_string_literal: true

module DependencyProxy
  class ImageTtlGroupPolicyWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
    include DependencyProxy::Expireable

    data_consistency :always

    feature_category :dependency_proxy

    def perform
      DependencyProxy::ImageTtlGroupPolicy.enabled.each do |policy|
        qualified_blobs = policy.group.dependency_proxy_blobs.active.read_before(policy.ttl)
        qualified_manifests = policy.group.dependency_proxy_manifests.active.read_before(policy.ttl)

        expire_artifacts(qualified_blobs)
        expire_artifacts(qualified_manifests)
      end

      log_counts
    end

    private

    def log_counts
      use_replica_if_available do
        expired_blob_count = DependencyProxy::Blob.expired.count
        expired_manifest_count = DependencyProxy::Manifest.expired.count
        processing_blob_count = DependencyProxy::Blob.processing.count
        processing_manifest_count = DependencyProxy::Manifest.processing.count
        error_blob_count = DependencyProxy::Blob.error.count
        error_manifest_count = DependencyProxy::Manifest.error.count

        log_extra_metadata_on_done(:expired_dependency_proxy_blob_count, expired_blob_count)
        log_extra_metadata_on_done(:expired_dependency_proxy_manifest_count, expired_manifest_count)
        log_extra_metadata_on_done(:processing_dependency_proxy_blob_count, processing_blob_count)
        log_extra_metadata_on_done(:processing_dependency_proxy_manifest_count, processing_manifest_count)
        log_extra_metadata_on_done(:error_dependency_proxy_blob_count, error_blob_count)
        log_extra_metadata_on_done(:error_dependency_proxy_manifest_count, error_manifest_count)
      end
    end

    def use_replica_if_available(&block)
      ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries(&block)
    end
  end
end
