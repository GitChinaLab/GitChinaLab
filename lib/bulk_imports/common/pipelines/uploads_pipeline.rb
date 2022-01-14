# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class UploadsPipeline
        include Pipeline

        AVATAR_PATTERN = %r{.*\/#{BulkImports::UploadsExportService::AVATAR_PATH}\/(?<identifier>.*)}.freeze

        AvatarLoadingError = Class.new(StandardError)

        def extract(_context)
          download_service.execute
          decompression_service.execute
          extraction_service.execute

          upload_file_paths = Dir.glob(File.join(tmp_dir, '**', '*'))

          BulkImports::Pipeline::ExtractedData.new(data: upload_file_paths)
        end

        def load(context, file_path)
          avatar_path = AVATAR_PATTERN.match(file_path)

          return save_avatar(file_path) if avatar_path

          dynamic_path = file_uploader.extract_dynamic_path(file_path)

          return unless dynamic_path
          return if File.directory?(file_path)
          return if File.lstat(file_path).symlink?

          named_captures = dynamic_path.named_captures.symbolize_keys

          UploadService.new(context.portable, File.open(file_path, 'r'), file_uploader, **named_captures).execute
        end

        def after_run(_)
          FileUtils.remove_entry(tmp_dir) if Dir.exist?(tmp_dir)
        end

        private

        def download_service
          BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: context.entity.relation_download_url_path(relation),
            dir: tmp_dir,
            filename: targz_filename
          )
        end

        def decompression_service
          BulkImports::FileDecompressionService.new(dir: tmp_dir, filename: targz_filename)
        end

        def extraction_service
          BulkImports::ArchiveExtractionService.new(tmpdir: tmp_dir, filename: tar_filename)
        end

        def relation
          BulkImports::FileTransfer::BaseConfig::UPLOADS_RELATION
        end

        def tar_filename
          "#{relation}.tar"
        end

        def targz_filename
          "#{tar_filename}.gz"
        end

        def tmp_dir
          @tmp_dir ||= Dir.mktmpdir('bulk_imports')
        end

        def file_uploader
          @file_uploader ||= if context.entity.group?
                               NamespaceFileUploader
                             else
                               FileUploader
                             end
        end

        def save_avatar(file_path)
          File.open(file_path) do |avatar|
            service = context.entity.update_service.new(portable, current_user, avatar: avatar)

            unless service.execute
              raise AvatarLoadingError, portable.errors.full_messages.to_sentence
            end
          end
        end
      end
    end
  end
end
