# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner, class: 'Ci::Runner' do
    sequence(:description) { |n| "My runner#{n}" }

    platform { "darwin" }
    active { true }
    access_level { :not_protected }

    runner_type { :instance_type }

    transient do
      groups { [] }
      projects { [] }
    end

    after(:build) do |runner, evaluator|
      evaluator.projects.each do |proj|
        runner.runner_projects << build(:ci_runner_project, project: proj)
      end

      evaluator.groups.each do |group|
        runner.runner_namespaces << build(:ci_runner_namespace, namespace: group)
      end
    end

    trait :online do
      contacted_at { Time.now }
    end

    trait :instance do
      runner_type { :instance_type }
    end

    trait :group do
      runner_type { :group_type }

      after(:build) do |runner, evaluator|
        if runner.runner_namespaces.empty?
          runner.runner_namespaces << build(:ci_runner_namespace)
        end
      end
    end

    trait :project do
      runner_type { :project_type }

      after(:build) do |runner, evaluator|
        if runner.runner_projects.empty?
          runner.runner_projects << build(:ci_runner_project)
        end
      end
    end

    trait :without_projects do
      # we use that to create invalid runner:
      # the one without projects
      after(:create) do |runner, evaluator|
        runner.runner_projects.delete_all
      end
    end

    trait :inactive do
      active { false }
    end

    trait :ref_protected do
      access_level { :ref_protected }
    end

    trait :tagged_only do
      run_untagged { false }

      tag_list { %w(tag1 tag2) }
    end

    trait :locked do
      locked { true }
    end
  end
end
