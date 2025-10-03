# Centralized error handling logic
module BotErrorHandler
  def self.handle_command_with_logging(event, command_name, block, *args)
    # Log command execution
    user_info = event.user ? "#{event.user.username} (#{event.user.id})" : "unknown"
    message = "Command executed: /#{command_name} by #{user_info}"
    message += " with options: #{event.options.inspect}" if event.options&.any?
    log_info(message)

    # Execute command
    result = block.call(event, *args)

    # Log success
    log_info("✅ /#{command_name} completed")
    result
  rescue => e
    # Log error
    error_message = "Error in /#{command_name}: #{e.message}"
    log_error(error_message)
    log_error(e.backtrace.join("\n"))

    # Respond with error - try edit_response first, fall back to respond
    error_response = "❌ Error inesperado. Inténtalo de nuevo más tarde."
    begin
      event.edit_response(content: error_response)
    rescue
      event.respond(content: error_response, ephemeral: true)
    end
  end

  private

  def self.log_info(message)
    Rails.logger.info(message)
    broadcast_log(message, :info)
  end

  def self.log_error(message)
    Rails.logger.error(message)
    broadcast_log(message, :error)
  end

  def self.broadcast_log(message, level)
    ActionCable.server.broadcast(
      "bot_updates",
      {
        type: "log",
        message: message.to_s,
        timestamp: Time.current.iso8601,
        level: level.to_s
      }
    )
  rescue => e
    # Silently fail if ActionCable broadcast fails
    Rails.logger.debug("Failed to broadcast log: #{e.message}")
  end
end

# Monkey-patch ApplicationCommandEventHandler to add automatic error handling for subcommands
module Discordrb::Events
  class ApplicationCommandEventHandler
    alias_method :original_subcommand, :subcommand

    def subcommand(name, &block)
      original_subcommand(name) do |event|
        BotErrorHandler.handle_command_with_logging(event, name, block)
      end
    end
  end
end

# Also wrap top-level application_command blocks
module Discordrb::EventContainer
  alias_method :original_application_command, :application_command

  def application_command(name, **kwargs, &block)
    if block
      original_application_command(name, **kwargs) do |event|
        BotErrorHandler.handle_command_with_logging(event, name, block)
      end
    else
      original_application_command(name, **kwargs)
    end
  end

  # Wrap autocomplete handlers with error handling
  alias_method :original_autocomplete, :autocomplete

  def autocomplete(name, &block)
    original_autocomplete(name) do |event|
      BotErrorHandler.handle_command_with_logging(event, "autocomplete:#{name}", block)
    end
  end
end
