FactoryBot.define do
  factory :scheduled_message do
    name { Faker::Lorem.unique.word.capitalize + " Birthday" }
    description { Faker::Lorem.sentence }
    template { "Happy birthday {name}! 🎉" }
    schedule_type { "birthday" }
    schedule_day { 15 }
    schedule_month { 1 }
    schedule_time { "08:00" }
    enabled { true }
    channel_id { Faker::Number.number(digits: 18).to_s }
    created_by { association :user }
  end
end
