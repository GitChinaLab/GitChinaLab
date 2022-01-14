# frozen_string_literal: true
module Packages
  module Npm
    class CreatePackageService < ::Packages::CreatePackageService
      include Gitlab::Utils::StrongMemoize

      PACKAGE_JSON_NOT_ALLOWED_FIELDS = %w[readme readmeFilename].freeze

      def execute
        return error('Version is empty.', 400) if version.blank?
        return error('Package already exists.', 403) if current_package_exists?
        return error('File is too large.', 400) if file_size_exceeded?

        ApplicationRecord.transaction { create_npm_package! }
      end

      private

      def create_npm_package!
        package = create_package!(:npm, name: name, version: version)

        ::Packages::CreatePackageFileService.new(package, file_params).execute
        ::Packages::CreateDependencyService.new(package, package_dependencies).execute
        ::Packages::Npm::CreateTagService.new(package, dist_tag).execute

        package.create_npm_metadatum!(package_json: package_json)

        package
      end

      def current_package_exists?
        project.packages
               .npm
               .with_name(name)
               .with_version(version)
               .exists?
      end

      def name
        params[:name]
      end

      def version
        strong_memoize(:version) do
          params[:versions].each_key.first
        end
      end

      def version_data
        params[:versions][version]
      end

      def package_json
        version_data.except(*PACKAGE_JSON_NOT_ALLOWED_FIELDS)
      end

      def dist_tag
        params['dist-tags'].each_key.first
      end

      def package_file_name
        strong_memoize(:package_file_name) do
          "#{name}-#{version}.tgz"
        end
      end

      def attachment
        strong_memoize(:attachment) do
          params['_attachments'][package_file_name]
        end
      end

      # TODO (technical debt): Extract the package size calculation to its own component and unit test it separately.
      def calculated_package_file_size
        strong_memoize(:calculated_package_file_size) do
          # This calculation is based on:
          # 1. 4 chars in a Base64 encoded string are 3 bytes in the original string. Meaning 1 char is 0.75 bytes.
          # 2. The encoded string may have 1 or 2 extra '=' chars used for padding. Each padding char means 1 byte less in the original string.
          # Reference:
          # - https://blog.aaronlenoir.com/2017/11/10/get-original-length-from-base-64-string/
          # - https://en.wikipedia.org/wiki/Base64#Decoding_Base64_with_padding
          encoded_data = attachment['data']
          ((encoded_data.length * 0.75 ) - encoded_data[-2..].count('=')).to_i
        end
      end

      def file_params
        {
          file:      CarrierWaveStringFile.new(Base64.decode64(attachment['data'])),
          size:      calculated_package_file_size,
          file_sha1: version_data[:dist][:shasum],
          file_name: package_file_name,
          build:     params[:build]
        }
      end

      def package_dependencies
        _version, versions_data = params[:versions].first
        versions_data
      end

      def file_size_exceeded?
        project.actual_limits.exceeded?(:npm_max_file_size, calculated_package_file_size)
      end
    end
  end
end
