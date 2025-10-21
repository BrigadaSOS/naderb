class ScheduledMessage < ApplicationRecord
  CONSUMER_TYPES = %w[discord].freeze
  DATA_QUERIES = %w[birthdays_today].freeze

  attribute :created_by_id, :uuid_v7

  belongs_to :created_by, class_name: "User"
  has_many :sent_notifications, dependent: :destroy
  has_many :executions, class_name: "ScheduledMessageExecution", dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :template, presence: true
  validates :schedule, presence: true
  validates :consumer_type, presence: true, inclusion: { in: CONSUMER_TYPES }
  validates :channel_id, presence: true
  validates :timezone, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validates :data_query, inclusion: { in: DATA_QUERIES, allow_nil: true, allow_blank: true }

  validate :validate_schedule_syntax

  scope :active, -> { where(enabled: true) }
  scope :for_consumer_type, ->(type) { where(consumer_type: type) }

  # Render the ERB template with provided locals
  # Returns plain text output
  def render_template(locals = {})
    # Add default time/date variables
    now = Time.current.in_time_zone(timezone)
    default_locals = {
      date: now.strftime("%Y-%m-%d"),
      time: now.strftime("%I:%M %p"),
      day_of_week: now.strftime("%A"),
      month: now.strftime("%B"),
      year: now.year
    }

    all_locals = default_locals.merge(locals)

    # Render ERB template
    erb = ERB.new(template, trim_mode: "-")
    context = RenderContext.new(all_locals)
    erb.result(context.get_binding)
  end

  # Check if this message was already executed recently based on schedule frequency
  def already_executed_recently?
    return false if executions.empty?

    last_execution = executions.order(executed_at: :desc).first

    # Determine frequency from schedule string
    if schedule.include?("every hour") || schedule.include?("hourly")
      last_execution.executed_at > 50.minutes.ago
    elsif schedule.include?("every day") || schedule.include?("daily") || schedule.match?(/at \d+/)
      last_execution.executed_at > 23.hours.ago
    elsif schedule.include?("every week") || schedule.include?("weekly")
      last_execution.executed_at > 6.days.ago
    else
      # Default: assume daily for safety
      last_execution.executed_at > 23.hours.ago
    end
  end

  private

  def validate_schedule_syntax
    return if schedule.blank?

    # Basic validation - Solid Queue will validate more strictly
    # Just check it's not obviously wrong
    valid_patterns = [
      /every \d+ (second|minute|hour|day|week|month)s?/i,
      /every (second|minute|hour|day|week|month)/i,
      /at \d{1,2}(:\d{2})?\s*(am|pm)?/i,
      /on (monday|tuesday|wednesday|thursday|friday|saturday|sunday)/i
    ]

    unless valid_patterns.any? { |pattern| schedule.match?(pattern) }
      errors.add(:schedule, "doesn't match expected Solid Queue syntax (e.g., 'every day at 8am', 'every 2 hours')")
    end
  end

  # Context class for ERB rendering with instance variable support
  class RenderContext
    def initialize(locals)
      locals.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def get_binding
      binding
    end
  end
end
