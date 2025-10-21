class SentNotification < ApplicationRecord
  belongs_to :scheduled_message

  validates :sent_at, presence: true
  validates :scheduled_message_id, uniqueness: { scope: [:sent_at], message: "can only send one notification per scheduled message per execution" }

  scope :today, -> { where("sent_at >= ?", Time.current.beginning_of_day) }
end
