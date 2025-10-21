# Liquid Drop for Birthday objects
# This safely exposes Birthday data to Liquid templates without allowing arbitrary method calls
class BirthdayDrop < Liquid::Drop
  def initialize(birthday)
    @birthday = birthday
  end

  def display_name
    @birthday.display_name
  end

  def username
    @birthday.username
  end

  def discord_uid
    @birthday.discord_uid
  end

  def mention
    @birthday.mention
  end

  def month
    @birthday.month
  end

  def day
    @birthday.day
  end

  def month_name
    @birthday.month_name
  end

  def to_s
    @birthday.to_s
  end
end
