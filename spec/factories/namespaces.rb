# frozen_string_literal: true

FactoryBot.define do
  # This factory is called :namespace but actually maps (and always has) to User type
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74152#note_730034103 for context
  factory :namespace, class: 'Namespaces::UserNamespace' do
    sequence(:name) { |n| "namespace#{n}" }
    type { Namespaces::UserNamespace.sti_name }

    path { name.downcase.gsub(/\s/, '_') }

    owner { association(:user, strategy: :build, namespace: instance, username: path) }

    trait :with_aggregation_schedule do
      after(:create) do |namespace|
        create(:namespace_aggregation_schedules, namespace: namespace)
      end
    end

    trait :with_root_storage_statistics do
      after(:create) do |namespace|
        create(:namespace_root_storage_statistics, namespace: namespace)
      end
    end

    trait :with_namespace_settings do
      after(:create) do |namespace|
        create(:namespace_settings, namespace: namespace)
      end
    end

    trait :shared_runners_disabled do
      shared_runners_enabled { false }
    end

    trait :allow_descendants_override_disabled_shared_runners do
      allow_descendants_override_disabled_shared_runners { true }
    end
  end
end
