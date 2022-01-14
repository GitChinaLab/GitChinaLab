# frozen_string_literal: true

module Peek
  module Views
    class ActiveRecord < DetailedView
      DEFAULT_THRESHOLDS = {
        calls: 100,
        duration: 3000,
        individual_call: 1000
      }.freeze

      THRESHOLDS = {
        production: {
          calls: 100,
          duration: 15000,
          individual_call: 5000
        }
      }.freeze

      def self.thresholds
        @thresholds ||= THRESHOLDS.fetch(Rails.env.to_sym, DEFAULT_THRESHOLDS)
      end

      def results
        super.merge(summary: summary)
      end

      private

      def summary
        detail_store.each_with_object({}) do |item, count|
          count_summary(item, count)
        end
      end

      def count_summary(item, count)
        if item[:cached].present?
          count[item[:cached]] ||= 0
          count[item[:cached]] += 1
        end

        if item[:transaction].present?
          count[item[:transaction]] ||= 0
          count[item[:transaction]] += 1
        end

        count[item[:db_role]] ||= 0
        count[item[:db_role]] += 1
      end

      def setup_subscribers
        super

        subscribe('sql.active_record') do |_, start, finish, _, data|
          detail_store << generate_detail(start, finish, data) if Gitlab::PerformanceBar.enabled_for_request?
        end
      end

      def generate_detail(start, finish, data)
        {
          start: start,
          duration: finish - start,
          sql: data[:sql].strip,
          backtrace: Gitlab::BacktraceCleaner.clean_backtrace(caller),
          cached: data[:cached] ? 'Cached' : '',
          transaction: data[:connection].transaction_open? ? 'In a transaction' : '',
          db_role: db_role(data),
          db_config_name: "Config name: #{::Gitlab::Database.db_config_name(data[:connection])}"
        }
      end

      def db_role(data)
        role = ::Gitlab::Database::LoadBalancing.db_role_for_connection(data[:connection]) ||
          ::Gitlab::Database::LoadBalancing::ROLE_UNKNOWN

        "Role: #{role.to_s.capitalize}"
      end

      def format_call_details(call)
        if ENV['GITLAB_MULTIPLE_DATABASE_METRICS']
          super
        else
          super.except(:db_config_name)
        end
      end
    end
  end
end
