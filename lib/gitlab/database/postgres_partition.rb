# frozen_string_literal: true

module Gitlab
  module Database
    class PostgresPartition < SharedModel
      self.primary_key = :identifier

      belongs_to :postgres_partitioned_table, foreign_key: 'parent_identifier', primary_key: 'identifier'

      scope :for_identifier, ->(identifier) do
        raise ArgumentError, "Partition name is not fully qualified with a schema: #{identifier}" unless identifier =~ /^\w+\.\w+$/

        where(primary_key => identifier)
      end

      scope :by_identifier, ->(identifier) do
        for_identifier(identifier).first!
      end

      scope :for_parent_table, ->(name) { where("parent_identifier = concat(current_schema(), '.', ?)", name).order(:name) }

      def to_s
        name
      end
    end
  end
end
