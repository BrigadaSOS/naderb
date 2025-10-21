FactoryBot.define do
  factory :scheduled_message do
    name { Faker::Lorem.unique.word.capitalize + " Message" }
    description { Faker::Lorem.sentence }
    template { "Test message" }
    schedule { "every day at 8am" }
    data_query { nil }
    consumer_type { "discord" }
    timezone { "America/Mexico_City" }
    enabled { true }
    channel_id { Faker::Number.number(digits: 18).to_s }
    conditions { nil }
    created_by { association :user }
  end
end
