# frozen_string_literal: true

require 'ostruct'

module RspecFlaky
  ALLOWED_ATTRIBUTES = %i[
    example_id
    file
    line
    description
    first_flaky_at
    last_flaky_at
    last_flaky_job
    last_attempts_count
    flaky_reports
  ].freeze

  # This represents a flaky RSpec example and is mainly meant to be saved in a JSON file
  class FlakyExample
    def initialize(example_hash)
      @attributes = {
        first_flaky_at: Time.now,
        last_flaky_at: Time.now,
        last_flaky_job: nil,
        last_attempts_count: example_hash[:attempts],
        flaky_reports: 0
      }.merge(example_hash.slice(*ALLOWED_ATTRIBUTES))

      %i[first_flaky_at last_flaky_at].each do |attr|
        attributes[attr] = Time.parse(attributes[attr]) if attributes[attr].is_a?(String)
      end
    end

    def update_flakiness!(last_attempts_count: nil)
      attributes[:first_flaky_at] ||= Time.now
      attributes[:last_flaky_at] = Time.now
      attributes[:flaky_reports] += 1
      attributes[:last_attempts_count] = last_attempts_count if last_attempts_count

      if ENV['CI_JOB_URL']
        attributes[:last_flaky_job] = "#{ENV['CI_JOB_URL']}"
      end
    end

    def to_h
      attributes.dup
    end

    private

    attr_reader :attributes
  end
end
