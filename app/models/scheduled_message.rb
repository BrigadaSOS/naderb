class ScheduledMessage < ApplicationRecord
  CONSUMER_TYPES = %w[discord].freeze
  DATA_QUERIES = %w[birthdays].freeze

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
  scope :due, -> { active.where("next_run_at <= ?", Time.current + 30.seconds) }

  before_validation :set_initial_next_run_at, on: :create
  after_save :recalculate_next_run_at_if_needed

  # Render the Liquid template with provided locals
  # Returns plain text output
  def render_template(locals = {})
    # Convert Birthday objects to BirthdayDrops for safe template access
    if locals[:birthdays].is_a?(Array)
      locals[:birthdays] = locals[:birthdays].map { |b| BirthdayDrop.new(b) }
    end

    # Liquid requires string keys
    string_locals = locals.deep_stringify_keys

    # Parse and render Liquid template with strict mode
    liquid_template = Liquid::Template.parse(template)
    liquid_template.render(string_locals, strict_variables: true, strict_filters: true)
  rescue Liquid::Error => e
    Rails.logger.error "Liquid template error for message #{id}: #{e.message}"
    raise "Template error: #{e.message}"
  end

  # Calculate the next time this message should run based on its schedule
  # @param from_time [Time] The time to calculate from (defaults to current time)
  # @return [Time] The next scheduled run time in UTC
  def calculate_next_run_at(from_time = Time.current)
    # Parse the schedule using Fugit
    parsed_schedule = Fugit.parse(schedule)

    unless parsed_schedule
      Rails.logger.error "Failed to parse schedule '#{schedule}' for message #{id}"
      # Default to 1 hour from now if parsing fails
      return from_time + 1.hour
    end

    # Convert from_time to the message's timezone
    tz = ActiveSupport::TimeZone[timezone]
    from_time_in_tz = from_time.in_time_zone(tz)

    # Calculate next occurrence
    next_time = parsed_schedule.next_time(from_time_in_tz)

    if next_time.nil?
      Rails.logger.error "Failed to calculate next time for schedule '#{schedule}' for message #{id}"
      return from_time + 1.hour
    end

    # Convert back to UTC for storage
    next_time.utc
  end

  private

  # Set initial next_run_at when creating a new message
  def set_initial_next_run_at
    self.next_run_at ||= calculate_next_run_at(Time.current) if schedule.present? && timezone.present?
  end

  # Recalculate next_run_at if schedule or timezone changed
  def recalculate_next_run_at_if_needed
    if saved_change_to_schedule? || saved_change_to_timezone?
      update_column(:next_run_at, calculate_next_run_at(Time.current))
    end
  end

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

end
