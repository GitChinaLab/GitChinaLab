# frozen_string_literal: true

module Gitlab
  module ExceptionLogFormatter
    class << self
      def format!(exception, payload)
        return unless exception

        # Elasticsearch/Fluentd don't handle nested structures well.
        # Use periods to flatten the fields.
        payload.merge!(
          'exception.class' => exception.class.name,
          'exception.message' => exception.message
        )

        if exception.backtrace
          payload['exception.backtrace'] = Rails.backtrace_cleaner.clean(exception.backtrace)
        end

        if sql = find_sql(exception)
          payload['exception.sql'] = sql
        end
      end

      def find_sql(exception)
        if exception.is_a?(ActiveRecord::StatementInvalid)
          # StatementInvalid may be caused by a statement timeout or a bad query
          normalize_query(exception.sql.to_s)
        elsif exception.cause.present?
          find_sql(exception.cause)
        end
      end

      private

      def normalize_query(sql)
        PgQuery.normalize(sql)
      rescue PgQuery::ParseError
        sql
      end
    end
  end
end
