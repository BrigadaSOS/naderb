module Messaging
  class DataQueryService
  # Execute a data query and return locals for template rendering
  # @param query_type [String] Type of query (e.g., "birthdays_today")
  # @param date [Time] The date to query for (defaults to current time)
  # @param timezone [String] Timezone for date calculations
  # @return [Hash] Hash of locals to pass to ERB template
  def execute(query_type, date: Time.current, timezone: "America/Mexico_City")
    return {} if query_type.blank?

    # Convert date to specified timezone
    @date = date.in_time_zone(timezone)

    case query_type
    when "birthdays"
      birthdays_query
    else
      Rails.logger.warn "Unknown data query type: #{query_type}"
      {}
    end
  end

  # Get metadata about available variables for a query type
  # @param query_type [String] Type of query
  # @return [Hash] Metadata including description and variables
  def self.query_metadata(query_type)
    case query_type
    when "birthdays"
      {
        name: "All User Birthdays",
        description: "Fetches all user birthdays - use Liquid template to filter by day, month, etc.",
        variables: [
          {
            name: "birthdays",
            type: "Array<Birthday>",
            description: "Array of all Birthday objects, ordered by month and day"
          },
          {
            name: "current_month",
            type: "Integer",
            description: "Current month number (1-12)"
          },
          {
            name: "current_day",
            type: "Integer",
            description: "Current day of the month (1-31)"
          }
        ],
        object_properties: [
          {
            object: "Birthday (each item in @birthdays)",
            properties: [
              { name: "display_name", type: "String", description: "User's display name" },
              { name: "username", type: "String", description: "Discord username" },
              { name: "discord_uid", type: "String", description: "Discord user ID" },
              { name: "mention", type: "String", description: "Discord mention format (<@uid>)" },
              { name: "month", type: "Integer", description: "Birth month (1-12)" },
              { name: "day", type: "Integer", description: "Birth day (1-31)" },
              { name: "month_name", type: "String", description: "Birth month name (e.g., 'January')" },
              { name: "to_s", type: "String", description: "Formatted birthday (e.g., 'January 15')" }
            ]
          }
        ],
        example: <<~EXAMPLE
          Filter birthdays today (skips if no birthdays):
          {% assign today_birthdays = birthdays | where: "month", current_month | where: "day", current_day %}
          {% if today_birthdays.size > 0 %}
          🎉 Happy Birthday! 🎉
          {% for birthday in today_birthdays %}
          Happy Birthday {{ birthday.mention }}! 🎂
          {% endfor %}
          {% endif %}

          Filter birthdays this month:
          {% assign month_birthdays = birthdays | where: "month", current_month %}
          🎂 {{ "now" | date: "%B" }} Birthdays:
          {% for birthday in month_birthdays %}
          • {{ birthday.day }} - {{ birthday.display_name }}
          {% endfor %}
          Total: {{ month_birthdays.size }}

          All birthdays:
          {% for birthday in birthdays %}
          {{ birthday.to_s }} - {{ birthday.username }}
          {% endfor %}

          Current date helpers:
          Month name: {{ "now" | date: "%B" }}
          Full date: {{ "now" | date: "%Y-%m-%d" }}
        EXAMPLE
      }
    else
      nil
    end
  end

  # Get list of all available query types with their metadata
  def self.available_queries
    ScheduledMessage::DATA_QUERIES.map do |query_type|
      metadata = query_metadata(query_type)
      {
        value: query_type,
        label: metadata[:name],
        description: metadata[:description]
      }
    end
  end

  private

  def birthdays_query
    # Find all active users with birthdays, ordered by month and day
    users = User.where(active: true)
                .where.not(birthday_month: nil)
                .where.not(birthday_day: nil)
                .order(:birthday_month, :birthday_day, :username)

    # Wrap users in BirthdayDrops for safe template access
    birthdays = users.map { |user| BirthdayDrop.new(user) }

    {
      birthdays: birthdays,
      current_month: @date.month,
      current_day: @date.day
    }
  end
end
end
