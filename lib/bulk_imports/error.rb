# frozen_string_literal: true

module BulkImports
  class Error < StandardError
    def self.unsupported_gitlab_version
      self.new("Unsupported GitLab Version. Minimum Supported Gitlab Version #{BulkImport::MIN_MAJOR_VERSION}.")
    end
  end
end
