FactoryBot.define do
  factory :scheduled_message_execution do
    scheduled_message { nil }
    executed_at { "2025-10-21 00:05:37" }
    status { "MyString" }
    consumer_type { "MyString" }
    result_data { "MyText" }
  end
end
