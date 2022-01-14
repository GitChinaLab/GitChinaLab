# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class SingleNumericListPartition
        include Comparable

        def self.from_sql(table, partition_name, definition)
          # A list partition can support multiple values, but we only support a single number
          matches = definition.match(/FOR VALUES IN \('(?<value>\d+)'\)/)

          raise ArgumentError, 'Unknown partition definition' unless matches

          value = Integer(matches[:value])

          new(table, value, partition_name: partition_name)
        end

        attr_reader :table, :value

        def initialize(table, value, partition_name: nil )
          @table = table
          @value = value
          @partition_name = partition_name
        end

        def partition_name
          @partition_name || "#{table}_#{value}"
        end

        def to_sql
          <<~SQL
            CREATE TABLE IF NOT EXISTS #{fully_qualified_partition}
            PARTITION OF #{conn.quote_table_name(table)}
            FOR VALUES IN (#{conn.quote(value)})
          SQL
        end

        def to_detach_sql
          <<~SQL
            ALTER TABLE #{conn.quote_table_name(table)}
            DETACH PARTITION #{fully_qualified_partition}
          SQL
        end

        def ==(other)
          table == other.table &&
            partition_name == other.partition_name &&
            value == other.value
        end
        alias_method :eql?, :==

        def hash
          [table, partition_name, value].hash
        end

        def <=>(other)
          return if table != other.table

          value <=> other.value
        end

        private

        def fully_qualified_partition
          "%s.%s" % [conn.quote_table_name(Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA), conn.quote_table_name(partition_name)]
        end

        def conn
          @conn ||= Gitlab::Database::SharedModel.connection
        end
      end
    end
  end
end
