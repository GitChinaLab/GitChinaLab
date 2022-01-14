# frozen_string_literal: true

FactoryBot.define do
  factory :project_feature_usage do
    project

    trait :dvcs_cloud do
      jira_dvcs_cloud_last_sync_at { Time.current }
    end

    trait :dvcs_server do
      jira_dvcs_server_last_sync_at { Time.current }
    end
  end
end
