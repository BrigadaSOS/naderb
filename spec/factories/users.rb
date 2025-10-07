FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user_#{n}" }
    sequence(:discord_uid) { |n| "discord_uid_#{n}" }
    provider { "discord" }
    password { Faker::Internet.password(min_length: 8, max_length: 20) }
    display_name { Faker::Internet.username(specifier: 5..12) }
    profile_image_url { Faker::Avatar.image }
    locale { I18n.available_locales.sample.to_s }
    active { true }

    trait :admin do
      after(:create) do |user|
        user.impersonated_roles = Setting.discord_admin_roles
      end
    end

    trait :moderator do
      after(:create) do |user|
        user.impersonated_roles = Setting.discord_moderator_roles
      end
    end

    trait :trusted_user do
      after(:create) do |user|
        user.impersonated_roles = Setting.trusted_user_roles
      end
    end

    trait :inactive do
      active { false }
      # Set a past date for when user became inactive
      updated_at { Faker::Time.backward(days: 30) }
    end

    trait :with_tags do
      transient do
        tags_count { 3 }
      end

      after(:create) do |user, evaluator|
        create_list(:tag, evaluator.tags_count, user: user)
      end
    end

    trait :with_real_name do
      display_name { Faker::Name.name }
    end

    trait :recently_created do
      created_at { Faker::Time.between(from: 7.days.ago, to: Time.now) }
    end

    trait :veteran do
      created_at { Faker::Time.between(from: 2.years.ago, to: 1.year.ago) }
    end
  end
end
