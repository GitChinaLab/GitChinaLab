# frozen_string_literal: true

FactoryBot.define do
  factory :project_member do
    user
    source { association(:project) }
    maintainer

    trait(:guest)     { access_level { ProjectMember::GUEST } }
    trait(:reporter)  { access_level { ProjectMember::REPORTER } }
    trait(:developer) { access_level { ProjectMember::DEVELOPER } }
    trait(:maintainer) { access_level { ProjectMember::MAINTAINER } }
    trait(:access_request) { requested_at { Time.now } }

    trait(:invited) do
      user_id { nil }
      invite_token { 'xxx' }
      sequence :invite_email do |n|
        "email#{n}@email.com"
      end
    end

    trait :blocked do
      after(:build) { |project_member, _| project_member.user.block! }
    end

    transient do
      tasks_to_be_done { [] }
    end

    after(:build) do |project_member, evaluator|
      if evaluator.tasks_to_be_done.present?
        build(:member_task, member: project_member, project: project_member.source, tasks_to_be_done: evaluator.tasks_to_be_done)
      end
    end
  end
end
