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
    when "birthdays_today"
      birthdays_today_query
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
    when "birthdays_today"
      {
        name: "Users with Birthdays Today",
        description: "Fetches birthdays for the current day",
        variables: [
          {
            name: "@birthdays",
            type: "Array<Birthday>",
            description: "Array of Birthday objects for today"
          },
          {
            name: "@birthdays_count",
            type: "Integer",
            description: "Number of birthdays today"
          },
          {
            name: "@current_month",
            type: "String",
            description: "Current month name (e.g., 'January')"
          },
          {
            name: "@current_day",
            type: "Integer",
            description: "Current day of the month (e.g., 15)"
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
              { name: "to_s", type: "String", description: "Formatted birthday (e.g., 'January 15')" },
              { name: "today?(date)", type: "Boolean", description: "Check if birthday is on given date" },
              { name: "in_month?(month)", type: "Boolean", description: "Check if birthday is in given month" }
            ]
          }
        ],
        example: <<~EXAMPLE
          🎉 Birthday Celebrations Today! 🎉

          <% @birthdays.each do |birthday| %>
          Happy Birthday <%= birthday.mention %>! 🎂
          <%= birthday.display_name %> (@<%= birthday.username %>) - Born on <%= birthday.to_s %>
          <% end %>

          Total birthdays today: <%= @birthdays_count %>

          You can also filter by month:
          <% birthdays_this_month = @birthdays.select { |b| b.in_month?(@current_month) } %>
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

  def birthdays_today_query
    month = @date.month
    day = @date.day

    # Find all users with birthdays today
    users = User.where(birthday_month: month, birthday_day: day, active: true).order(:username)

    # Wrap users in Birthday objects
    birthdays = users.map { |user| Birthday.new(user) }

    {
      birthdays: birthdays,
      birthdays_count: birthdays.count,
      current_month: Date::MONTHNAMES[month],
      current_day: day
    }
  end
end
