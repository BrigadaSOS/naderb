class ScheduledMessageExecution < ApplicationRecord
  STATUSES = %w[success error].freeze

  belongs_to :scheduled_message

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :consumer_type, presence: true
  validates :executed_at, presence: true

  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "error") }
  scope :recent, ->(limit = 10) { order(executed_at: :desc).limit(limit) }
  scope :today, -> { where("executed_at >= ?", Time.current.beginning_of_day) }

  # Serialize result_data as JSON
  serialize :result_data, coder: JSON
end
