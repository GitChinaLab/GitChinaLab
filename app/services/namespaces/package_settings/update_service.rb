# frozen_string_literal: true

module Namespaces
  module PackageSettings
    class UpdateService < BaseContainerService
      include Gitlab::Utils::StrongMemoize

      ALLOWED_ATTRIBUTES = %i[maven_duplicates_allowed
                              maven_duplicate_exception_regex
                              generic_duplicates_allowed
                              generic_duplicate_exception_regex].freeze

      def execute
        return ServiceResponse.error(message: 'Access Denied', http_status: 403) unless allowed?

        if package_settings.update(package_settings_params)
          ServiceResponse.success(payload: { package_settings: package_settings })
        else
          ServiceResponse.error(
            message: package_settings.errors.full_messages.to_sentence || 'Bad request',
            http_status: 400
          )
        end
      end

      private

      def package_settings
        strong_memoize(:package_settings) do
          @container.package_settings
        end
      end

      def allowed?
        Ability.allowed?(current_user, :create_package_settings, @container)
      end

      def package_settings_params
        @params.slice(*ALLOWED_ATTRIBUTES)
      end
    end
  end
end
