# frozen_string_literal: true

# This file should only be used by sub-classes, not directly by any clients of the sub-classes

# Explicitly load parts of ActiveSupport because MailRoom does not load
# Rails.
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

# Explicitly load Redis::Store::Factory so we can read Redis configuration in
# TestEnv
require 'redis/store/factory'

module Gitlab
  module Redis
    class Wrapper
      class << self
        delegate :params, :url, :store, to: :new

        def with
          pool.with { |redis| yield redis }
        end

        def version
          with { |redis| redis.info['redis_version'] }
        end

        def pool
          @pool ||= ConnectionPool.new(size: pool_size) { redis }
        end

        def pool_size
          # heuristic constant 5 should be a config setting somewhere -- related to CPU count?
          size = 5
          if Gitlab::Runtime.multi_threaded?
            size += Gitlab::Runtime.max_threads
          end

          size
        end

        def _raw_config
          return @_raw_config if defined?(@_raw_config)

          @_raw_config =
            begin
              if filename = config_file_name
                ERB.new(File.read(filename)).result.freeze
              else
                false
              end
            rescue Errno::ENOENT
              false
            end
        end

        def config_file_path(filename)
          path = File.join(rails_root, 'config', filename)
          return path if File.file?(path)
        end

        # We need this local implementation of Rails.root because MailRoom
        # doesn't load Rails.
        def rails_root
          File.expand_path('../../..', __dir__)
        end

        def config_fallback?
          config_file_name == config_fallback&.config_file_name
        end

        def config_file_name
          [
            # Instance specific config sources:
            ENV["GITLAB_REDIS_#{store_name.underscore.upcase}_CONFIG_FILE"],
            config_file_path("redis.#{store_name.underscore}.yml"),

            # The current Redis instance may have been split off from another one
            # (e.g. TraceChunks was split off from SharedState). There are
            # installations out there where the lowest priority config source
            # (resque.yml) contains bogus values. In those cases, config_file_name
            # should resolve to the instance we originated from (the
            # "config_fallback") rather than resque.yml.
            config_fallback&.config_file_name,

            # Global config sources:
            ENV['GITLAB_REDIS_CONFIG_FILE'],
            config_file_path('resque.yml')
          ].compact.first
        end

        def store_name
          name.demodulize
        end

        def config_fallback
          nil
        end

        def instrumentation_class
          return unless defined?(::Gitlab::Instrumentation::Redis)

          "::Gitlab::Instrumentation::Redis::#{store_name}".constantize
        end

        private

        def redis
          ::Redis.new(params)
        end
      end

      def initialize(rails_env = nil)
        @rails_env = rails_env || ::Rails.env
      end

      def params
        redis_store_options
      end

      def url
        raw_config_hash[:url]
      end

      def db
        redis_store_options[:db]
      end

      def sentinels
        raw_config_hash[:sentinels]
      end

      def sentinels?
        sentinels && !sentinels.empty?
      end

      def store(extras = {})
        ::Redis::Store::Factory.create(redis_store_options.merge(extras))
      end

      private

      def redis_store_options
        config = raw_config_hash
        redis_url = config.delete(:url)
        redis_uri = URI.parse(redis_url)

        config[:instrumentation_class] ||= self.class.instrumentation_class

        if redis_uri.scheme == 'unix'
          # Redis::Store does not handle Unix sockets well, so let's do it for them
          config[:path] = redis_uri.path
          query = redis_uri.query
          unless query.nil?
            queries = CGI.parse(redis_uri.query)
            db_numbers = queries["db"] if queries.key?("db")
            config[:db] = db_numbers[0].to_i if db_numbers.any?
          end

          config
        else
          redis_hash = ::Redis::Store::Factory.extract_host_options_from_uri(redis_url)
          # order is important here, sentinels must be after the connection keys.
          # {url: ..., port: ..., sentinels: [...]}
          redis_hash.merge(config)
        end
      end

      def raw_config_hash
        config_data = fetch_config

        config_hash =
          if config_data
            config_data.is_a?(String) ? { url: config_data } : config_data.deep_symbolize_keys
          else
            { url: '' }
          end

        if config_hash[:url].blank?
          config_hash[:url] = legacy_fallback_urls[self.class.store_name] || legacy_fallback_urls[self.class.config_fallback.store_name]
        end

        config_hash
      end

      # These URLs were defined for cache, queues, and shared_state in
      # code. They are used only when no config file exists at all for a
      # given instance. The configuration does not seem particularly
      # useful - it uses different ports on localhost - but we cannot
      # confidently delete it as we don't know if any instances rely on
      # this.
      #
      # DO NOT ADD new instances here. All new instances should define a
      # `.config_fallback`, which will then be used to look up this URL.
      def legacy_fallback_urls
        {
          'Cache' => 'redis://localhost:6380',
          'Queues' => 'redis://localhost:6381',
          'SharedState' => 'redis://localhost:6382'
        }
      end

      def fetch_config
        return false unless self.class._raw_config

        yaml = YAML.safe_load(self.class._raw_config, aliases: true)

        # If the file has content but it's invalid YAML, `load` returns false
        if yaml
          yaml.fetch(@rails_env, false)
        else
          false
        end
      end
    end
  end
end
