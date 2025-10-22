# Liquid Drop for User birthday data
# This safely exposes User birthday data to Liquid templates without allowing arbitrary method calls
class BirthdayDrop < Liquid::Drop
  def initialize(user)
    @user = user
  end

  def display_name
    @user.display_name
  end

  def username
    @user.username
  end

  def discord_uid
    @user.discord_uid
  end

  def mention
    "<@#{@user.discord_uid}>"
  end

  def month
    @user.birthday_month
  end

  def day
    @user.birthday_day
  end

  def month_name
    Date::MONTHNAMES[@user.birthday_month] if @user.birthday_month
  end

  def today?(date = Time.current)
    date.month == @user.birthday_month && date.day == @user.birthday_day
  end

  def in_month?(month_number)
    @user.birthday_month == month_number
  end

  def to_s
    "#{month_name} #{@user.birthday_day}"
  end
end
