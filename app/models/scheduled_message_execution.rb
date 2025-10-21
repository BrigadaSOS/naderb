class ScheduledMessageExecution < ApplicationRecord
  STATUSES = %w[success error skipped].freeze
  EXECUTION_TYPES = %w[scheduled manual].freeze

  belongs_to :scheduled_message

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :consumer_type, presence: true
  validates :executed_at, presence: true
  validates :execution_type, presence: true, inclusion: { in: EXECUTION_TYPES }

  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "error") }
  scope :skipped, -> { where(status: "skipped") }
  scope :scheduled, -> { where(execution_type: "scheduled") }
  scope :manual, -> { where(execution_type: "manual") }
  scope :recent, ->(limit = 10) { order(executed_at: :desc).limit(limit) }
  scope :today, -> { where("executed_at >= ?", Time.current.beginning_of_day) }

  # Serialize result_data as JSON
  serialize :result_data, coder: JSON
end
