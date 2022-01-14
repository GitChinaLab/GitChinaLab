# frozen_string_literal: true

# Archive Extraction Service allows extraction of contents
# from `tar` archives with an additional handling (removal)
# of file symlinks.
#
# @param tmpdir [String] A path where archive is located
# and where its contents are extracted.
# Tmpdir directory must be located under `Dir.tmpdir`.
# `BulkImports::Error` is raised if any other directory path is used.
#
# @param filename [String] Name of the file to extract contents from.
#
# @example
#   dir = Dir.mktmpdir
#   filename = 'things.tar'
#   BulkImports::ArchiveExtractionService.new(tmpdir: dir, filename: filename).execute
#   Dir.glob(File.join(dir, '**', '*'))
#   => ['/path/to/tmp/dir/extracted_file_1', '/path/to/tmp/dir/extracted_file_2', '/path/to/tmp/dir/extracted_file_3']
module BulkImports
  class ArchiveExtractionService
    include Gitlab::ImportExport::CommandLineUtil

    def initialize(tmpdir:, filename:)
      @tmpdir = tmpdir
      @filename = filename
      @filepath = File.join(@tmpdir, @filename)
    end

    def execute
      validate_filepath
      validate_tmpdir
      validate_symlink

      extract_archive
      remove_symlinks
      tmpdir
    end

    private

    attr_reader :tmpdir, :filename, :filepath

    def validate_filepath
      Gitlab::Utils.check_path_traversal!(filepath)
    end

    def validate_tmpdir
      raise(BulkImports::Error, 'Invalid target directory') unless File.expand_path(tmpdir).start_with?(Dir.tmpdir)
    end

    def validate_symlink
      raise(BulkImports::Error, 'Invalid file') if symlink?(filepath)
    end

    def symlink?(filepath)
      File.lstat(filepath).symlink?
    end

    def extract_archive
      untar_xf(archive: filepath, dir: tmpdir)
    end

    def extracted_files
      Dir.glob(File.join(tmpdir, '**', '*'))
    end

    def remove_symlinks
      extracted_files.each do |path|
        FileUtils.rm(path) if symlink?(path)
      end
    end
  end
end
