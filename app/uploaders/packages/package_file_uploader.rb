# frozen_string_literal: true
class Packages::PackageFileUploader < GitlabUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  storage_options Gitlab.config.packages

  after :store, :schedule_background_upload

  alias_method :upload, :model

  def filename
    model.file_name
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    raise ObjectNotReadyError, "Package model not ready" unless model.id

    package_segment = model.package.debian? ? 'debian' : model.package.id

    Gitlab::HashedPath.new('packages', package_segment, 'files', model.id, root_hash: model.package.project_id)
  end
end
