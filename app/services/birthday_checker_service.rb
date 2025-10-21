class BirthdayCheckerService
  MEXICO_TIMEZONE = "America/Mexico_City"

  def initialize
    @bot = DiscordBot.current if defined?(DiscordBot)
  end

  # Check for today's birthdays and send notifications
  def check_and_send_birthday_notifications
    Rails.logger.info "Starting birthday check and notification process"

    # Get today's date in Mexico timezone
    mexico_time = Time.current.in_time_zone(MEXICO_TIMEZONE)
    month = mexico_time.month
    day = mexico_time.day

    # Find all users with birthdays today
    users_with_birthdays = User.where(birthday_month: month, birthday_day: day).active

    Rails.logger.info "Found #{users_with_birthdays.count} users with birthdays today"

    # Find all active birthday messages scheduled for today
    scheduled_messages = ScheduledMessage.active.for_birthday.for_today(month, day)

    Rails.logger.info "Found #{scheduled_messages.count} active birthday messages scheduled for today"

    # Send each message to each user with a birthday
    notifications_sent = 0
    users_with_birthdays.each do |user|
      scheduled_messages.each do |message|
        if send_birthday_message(user, message)
          notifications_sent += 1
        end
      end
    end

    Rails.logger.info "Birthday notification process completed. Sent #{notifications_sent} messages"
    { success: true, notifications_sent: notifications_sent }
  rescue => e
    Rails.logger.error "Error in birthday notification process: #{e.message}\n#{e.backtrace.join("\n")}"
    { success: false, error: e.message }
  end

  private

  def send_birthday_message(user, scheduled_message)
    # Check if we've already sent this notification today
    if scheduled_message.already_sent_today?
      Rails.logger.info "Birthday message '#{scheduled_message.name}' already sent today for scheduled_message_id=#{scheduled_message.id}"
      return false
    end

    # Render the template for this user
    rendered_message = scheduled_message.render_for_user(user)

    # Send the message to Discord
    if send_discord_message(scheduled_message.channel_id, rendered_message)
      # Record that we sent this notification
      SentNotification.create(
        scheduled_message_id: scheduled_message.id,
        sent_at: Time.current,
        message_data: rendered_message
      )
      Rails.logger.info "Sent birthday message '#{scheduled_message.name}' to channel #{scheduled_message.channel_id} for user #{user.username}"
      return true
    else
      Rails.logger.error "Failed to send birthday message '#{scheduled_message.name}' to channel #{scheduled_message.channel_id}"
      return false
    end
  rescue => e
    Rails.logger.error "Error sending birthday message: #{e.message}\n#{e.backtrace.join("\n")}"
    false
  end

  def send_discord_message(channel_id, message_content)
    return false unless @bot

    begin
      channel = @bot.channel(channel_id.to_i)
      return false unless channel

      channel.send_message(message_content)
      true
    rescue => e
      Rails.logger.error "Error sending Discord message to channel #{channel_id}: #{e.message}"
      false
    end
  end
end
