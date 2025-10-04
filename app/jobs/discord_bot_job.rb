class DiscordBotJob < ApplicationJob
  queue_as :discord

  # Auto-restart on errors unless manually stopped
  retry_on StandardError, wait: :exponentially_longer, attempts: Float::INFINITY do |_job, error|
    next unless DiscordBotManagerService.should_run?

    DiscordBotJob.broadcast_error("Bot crashed: #{error.message}. Restarting...")
  end

  def perform
    return unless DiscordBotManagerService.should_run?

    broadcast_log "Starting Discord bot..."

    bot = Discordrb::Bot.new(token: Setting.discord_bot_token, intents: [ :server_messages ])

    # Include command modules
    bot.include!(AdminCommands)
    bot.include!(ProfileCommands)
    bot.include!(TagCommands)

    DiscordBotManagerService.set_bot_instance(bot)

    bot.ready { broadcast_log "Bot connected and running" }
    bot.run(:async)

    # Poll for stop signal
    loop do
      break unless DiscordBotManagerService.should_run?
      sleep 5
    end

    broadcast_log "Stopping bot..."
    bot.stop
    broadcast_log "Bot stopped gracefully"
  rescue StandardError => e
    broadcast_error("ERROR: #{e.message}")
    logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    bot&.stop rescue nil
    raise
  end

  private

  def broadcast_log(message)
    logger.info message
    broadcast(message, "info")
  end

  def broadcast_error(message)
    logger.error message
    broadcast(message, "error")
  end

  def broadcast(message, level)
    ActionCable.server.broadcast("bot_updates", {
      type: "log",
      message: message,
      timestamp: Time.current.iso8601,
      level: level
    })
  rescue => e
    Rails.logger.debug "Failed to broadcast: #{e.message}"
  end

  def self.broadcast_error(message)
    ActionCable.server.broadcast("bot_updates", {
      type: "log",
      message: message,
      timestamp: Time.current.iso8601,
      level: "warn"
    })
  rescue
    # Ignore broadcast errors in retry callback
  end
end
