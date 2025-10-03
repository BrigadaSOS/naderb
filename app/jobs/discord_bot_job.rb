class DiscordBotJob < ApplicationJob
  queue_as :discord

  # Don't retry automatically - we manage state manually
  discard_on StandardError

  POLL_INTERVAL_SECONDS = 5

  def perform(*args)
    broadcast_log "Starting Discord bot..."
    bot = nil

    begin
      token = Setting.discord_bot_token

      bot = Discordrb::Bot.new(token: token, intents: [ :server_messages ])

      # Include command modules
      bot.include!(AdminCommands)
      bot.include!(ProfileCommands)
      bot.include!(TagCommands)

      # Set up a ready event
      bot.ready do
        broadcast_log "Bot connected and running - entering polling loop"
      end

      # Run the bot asynchronously so we can poll for stop signal
      broadcast_log "Starting bot in async mode..."
      bot.run(:async)

      # Poll for stop signal
      loop do
        unless DiscordBotManagerService.should_run?
          broadcast_log "Stop signal detected, initiating graceful shutdown..."
          break
        end

        sleep POLL_INTERVAL_SECONDS
      end

      # Graceful shutdown
      broadcast_log "Calling bot.stop to disconnect gracefully..."
      bot.stop if bot
      broadcast_log "Bot stopped gracefully"

    rescue Interrupt, SignalException => e
      broadcast_log "Bot interrupted: #{e.class.name}"
      bot.stop if bot
    rescue StandardError => e
      error_message = "Error in Discord bot: #{e.message}"
      logger.error error_message
      logger.error e.backtrace.join("\n")

      broadcast_log "ERROR: #{error_message}"

      bot.stop if bot rescue nil

      raise
    end
  end

  private

  def broadcast_log(message, level = "info")
    logger.public_send(level, message)

    ActionCable.server.broadcast(
      "bot_updates",
      {
        type: "log",
        message: message,
        timestamp: Time.current.iso8601,
        level: level.to_s
      }
    )
  rescue => e
    Rails.logger.debug("Failed to broadcast log: #{e.message}")
  end
end
