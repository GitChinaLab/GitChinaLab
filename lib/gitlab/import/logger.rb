# frozen_string_literal: true

module Gitlab
  module Import
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'importer'
      end

      def default_attributes
        super.merge(feature_category: :importers)
      end
    end
  end
end
