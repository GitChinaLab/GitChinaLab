# frozen_string_literal: true

require 'securerandom'

FactoryBot.define do
  factory :import_failure do
    association :project, factory: :project

    created_at { Time.parse('2020-01-01T00:00:00Z') }
    exception_class { 'RuntimeError' }
    exception_message { 'Something went wrong' }
    source { 'method_call' }
    relation_key { 'issues' }
    relation_index { 1 }
    correlation_id_value { SecureRandom.uuid }

    trait :hard_failure do
      retry_count { 0 }
    end

    trait :soft_failure do
      retry_count { 1 }
    end
  end
end
