# frozen_string_literal: true

module BulkImports
  class UploadsExportService
    include Gitlab::ImportExport::CommandLineUtil

    BATCH_SIZE = 100
    AVATAR_PATH = 'avatar'

    def initialize(portable, export_path)
      @portable = portable
      @export_path = export_path
    end

    def execute
      portable.uploads.find_each(batch_size: BATCH_SIZE) do |upload| # rubocop: disable CodeReuse/ActiveRecord
        uploader = upload.retrieve_uploader

        next unless upload.exist?
        next unless uploader.file

        subdir_path = export_subdir_path(upload)
        mkdir_p(subdir_path)
        download_or_copy_upload(uploader, File.join(subdir_path, uploader.filename))
      rescue Errno::ENAMETOOLONG => e
        # Do not fail entire export process if downloaded file has filename that exceeds 255 characters.
        # Ignore raised exception, skip such upload, log the error and keep going with the export instead.
        Gitlab::ErrorTracking.log_exception(e, portable_id: portable.id, portable_class: portable.class.name, upload_id: upload.id)
      end
    end

    private

    attr_reader :portable, :export_path

    def export_subdir_path(upload)
      subdir = if upload.path == avatar_path
                 AVATAR_PATH
               else
                 upload.try(:secret).to_s
               end

      File.join(export_path, subdir)
    end

    def avatar_path
      @avatar_path ||= portable.avatar&.upload&.path
    end
  end
end
