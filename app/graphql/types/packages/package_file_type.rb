# frozen_string_literal: true

module Types
  module Packages
    class PackageFileType < BaseObject
      graphql_name 'PackageFile'
      description 'Represents a package file'
      authorize :read_package

      field :id, ::Types::GlobalIDType[::Packages::PackageFile], null: false, description: 'ID of the file.'
      field :created_at, Types::TimeType, null: false, description: 'Created date.'
      field :updated_at, Types::TimeType, null: false, description: 'Updated date.'
      field :size, GraphQL::Types::String, null: false, description: 'Size of the package file.'
      field :file_name, GraphQL::Types::String, null: false, description: 'Name of the package file.'
      field :download_path, GraphQL::Types::String, null: false, description: 'Download path of the package file.'
      field :file_md5, GraphQL::Types::String, null: true, description: 'Md5 of the package file.'
      field :file_sha1, GraphQL::Types::String, null: true, description: 'Sha1 of the package file.'
      field :file_sha256, GraphQL::Types::String, null: true, description: 'Sha256 of the package file.'
      field :file_metadata, Types::Packages::FileMetadataType, null: true,
        description: 'File metadata.'

      # NOTE: This method must be kept in sync with the union
      # type: `Types::Packages::FileMetadataType`.
      #
      # `Types::Packages::FileMetadataType.resolve_type(metadata, ctx)` must never raise.
      def file_metadata
        case object.package.package_type
        when 'conan'
          object.conan_file_metadatum
        when 'helm'
          object.helm_file_metadatum
        else
          nil
        end
      end
    end
  end
end
