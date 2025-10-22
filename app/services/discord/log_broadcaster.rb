# Centralized service for logging and broadcasting logs via ActionCable
# Replaces scattered Rails.logger + ActionCable.server.broadcast calls
#
# Usage:
#   Discord::Discord::LogBroadcaster.info("Bot started")
#   Discord::Discord::LogBroadcaster.error("Failed to connect", exception: e)
#   Discord::Discord::LogBroadcaster.warn("Deprecated feature used")
module Discord
  class Discord::LogBroadcaster
    CHANNEL = "bot_updates"

    class << self
    # Log and broadcast an info message
    # @param message [String] The message to log
    def info(message)
      Rails.logger.info(message)
      broadcast(message, "info")
    end

    # Log and broadcast an error message with optional exception details
    # @param message [String] The error message
    # @param exception [Exception, nil] Optional exception to extract details from
    def error(message, exception: nil)
      Rails.logger.error(message)
      if exception
        Rails.logger.error(exception.full_message)
      end

      broadcast(message, "error")
    end

    # Log and broadcast a warning message
    # @param message [String] The warning message
    def warn(message)
      Rails.logger.warn(message)
      broadcast(message, "warn")
    end

    # Log and broadcast a debug message
    # @param message [String] The debug message
    def debug(message)
      Rails.logger.debug(message)
      broadcast(message, "debug")
    end

    private

    # Broadcast a message to the ActionCable channel
    # @param message [String] The message to broadcast
    # @param level [String] The log level (info, error, warn, debug)
    def broadcast(message, level)
      ActionCable.server.broadcast(
        CHANNEL,
        {
          type: "log",
          message: message,
          timestamp: Time.current.iso8601,
          level: level
        }
      )
    rescue => e
      # Don't let broadcast failures crash the application
      Rails.logger.debug("Failed to broadcast log: #{e.message}")
    end
  end
  end
end
