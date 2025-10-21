FactoryBot.define do
  factory :sent_notification do
    scheduled_message { association :scheduled_message }
    sent_at { Time.current }
    message_data { "Happy birthday! 🎉" }
  end
end
