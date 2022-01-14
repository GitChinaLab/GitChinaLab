# frozen_string_literal: true

module Types
  module CiConfiguration
    module Sast
      class AnalyzersEntityInputType < BaseInputObject
        graphql_name 'SastCiConfigurationAnalyzersEntityInput'
        description 'Represents the analyzers entity in SAST CI configuration'

        argument :name, GraphQL::Types::String, required: true,
          description: 'Name of analyzer.'

        argument :enabled, GraphQL::Types::Boolean, required: true,
          description: 'State of the analyzer.'

        argument :variables, [::Types::CiConfiguration::Sast::EntityInputType],
          description: 'List of variables for the analyzer.',
          required: false
      end
    end
  end
end
