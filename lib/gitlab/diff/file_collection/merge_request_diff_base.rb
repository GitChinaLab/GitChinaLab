# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class MergeRequestDiffBase < Base
        extend ::Gitlab::Utils::Override

        delegate :real_size, :overflow?, :cache_key, to: :@merge_request_diff

        def initialize(merge_request_diff, diff_options:)
          @merge_request_diff = merge_request_diff

          super(merge_request_diff,
            project: merge_request_diff.project,
            diff_options: diff_options,
            diff_refs: merge_request_diff.diff_refs,
            fallback_diff_refs: merge_request_diff.fallback_diff_refs)
        end

        def diff_files(sorted: false)
          strong_memoize(:diff_files) do
            diff_files = super

            diff_files.each { |diff_file| highlight_cache.decorate(diff_file) }

            diff_files
          end
        end

        def raw_diff_files(sorted: false)
          # We force `sorted` to `false` as we don't need to sort the diffs when
          # dealing with `MergeRequestDiff` since we sort its files on create.
          super(sorted: false)
        end

        override :write_cache
        def write_cache
          highlight_cache.write_if_empty
          diff_stats_cache.write_if_empty(diff_stats_collection)
        end

        override :clear_cache
        def clear_cache
          highlight_cache.clear
          diff_stats_cache.clear
        end

        private

        def highlight_cache
          strong_memoize(:highlight_cache) do
            Gitlab::Diff::HighlightCache.new(self)
          end
        end

        def diff_stats_cache
          strong_memoize(:diff_stats_cache) do
            Gitlab::Diff::StatsCache.new(cachable_key: cache_key)
          end
        end

        override :diff_stats_collection
        def diff_stats_collection
          strong_memoize(:diff_stats) do
            next unless fetch_diff_stats?

            diff_stats_cache.read || super
          end
        end
      end
    end
  end
end
