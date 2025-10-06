FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "tag_#{n}" }
    content { "This is tag content" }
    guild_id { "999888777" }

    trait :with_image_url do
      content { "https://example.com/image.png" }
    end

    trait :long_content do
      content { "A" * 2000 }
    end
  end
end
