FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    sequence(:discord_uid) { |n| "discord_uid_#{n}" }
    provider { "discord" }
    password { "password123" }
    display_name { username }
    active { true }

    trait :admin do
      # In tests, we can use impersonated_roles to simulate admin access
      after(:create) do |user|
        # Set impersonated_roles if needed in development/test
        # This will be used in your admin? method via has_any_discord_role?
      end
    end

    trait :moderator do
      # Similar approach for moderators
    end

    trait :inactive do
      active { false }
    end
  end
end
