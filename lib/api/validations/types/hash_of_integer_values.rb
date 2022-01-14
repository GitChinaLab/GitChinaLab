# frozen_string_literal: true

module API
  module Validations
    module Types
      class HashOfIntegerValues
        def self.coerce
          lambda do |value|
            case value
            when Hash
              value.transform_values(&:to_i)
            else
              value
            end
          end
        end
      end
    end
  end
end
