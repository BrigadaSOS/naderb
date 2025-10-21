# Represents birthday data for template rendering
# This is a plain Ruby object (not ActiveRecord) that provides safe birthday data
# without exposing the full User model
class Birthday
  attr_reader :display_name, :username, :discord_uid, :month, :day, :month_name

  def initialize(user)
    @display_name = user.display_name
    @username = user.username
    @discord_uid = user.discord_uid
    @month = user.birthday_month
    @day = user.birthday_day
    @month_name = Date::MONTHNAMES[@month] if @month
  end

  # Returns a Discord mention string for this user
  # @return [String] Discord mention format <@discord_uid>
  def mention
    "<@#{@discord_uid}>"
  end

  # Check if birthday is today
  # @param date [Time] Date to check against (defaults to current time)
  # @return [Boolean]
  def today?(date = Time.current)
    date.month == @month && date.day == @day
  end

  # Check if birthday is in a specific month
  # @param month_number [Integer] Month number (1-12)
  # @return [Boolean]
  def in_month?(month_number)
    @month == month_number
  end

  # Format birthday as a readable string
  # @return [String] e.g., "January 15"
  def to_s
    "#{@month_name} #{@day}"
  end
end
