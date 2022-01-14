# frozen_string_literal: true

FactoryBot.define do
  factory :deploy_token do
    token { nil }
    token_encrypted { Gitlab::CryptoHelper.aes256_gcm_encrypt(SecureRandom.hex(50)) }
    sequence(:name) { |n| "PDT #{n}" }
    read_repository { true }
    read_registry { true }
    write_registry { false }
    read_package_registry { false }
    write_package_registry { false }
    revoked { false }
    expires_at { 5.days.from_now }
    deploy_token_type { DeployToken.deploy_token_types[:project_type] }

    trait :revoked do
      revoked { true }
    end

    trait :gitlab_deploy_token do
      name { DeployToken::GITLAB_DEPLOY_TOKEN_NAME }
    end

    trait :expired do
      expires_at { Date.today - 1.month }
    end

    trait :group do
      deploy_token_type { DeployToken.deploy_token_types[:group_type] }
    end

    trait :project do
      deploy_token_type { DeployToken.deploy_token_types[:project_type] }
    end

    trait :all_scopes do
      write_registry { true }
      read_package_registry { true }
      write_package_registry { true }
    end

    trait :dependency_proxy_scopes do
      write_registry { true }
    end
  end
end
