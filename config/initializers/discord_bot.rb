# Discord bot auto-starts with the Rails server
# Skip during rake tasks (migrations, db:create, etc.)
Rails.application.config.after_initialize do
  unless defined?(Rake)
    DiscordBotManagerService.start_bot
  end
end

# Handle Ctrl+C gracefully by setting stop signal for the bot
Signal.trap("INT") do
  Rails.logger.info "Received SIGINT (Ctrl+C), gracefully shutting down Discord bot..."

  begin
    if DiscordBotManagerService.running_or_starting?
      Rails.logger.info "Setting stop signal for bot..."
      DiscordBotManagerService.stop_bot

      # Give the job a moment to detect the signal and shut down gracefully
      sleep 5
      Rails.logger.info "Bot shutdown signal sent"
    end
  rescue => e
    Rails.logger.error "Error during bot shutdown: #{e.message}"
  end

  # Continue with default INT handler (shut down Rails)
  exit
end

Signal.trap("TERM") do
  Rails.logger.info "Received SIGTERM, gracefully shutting down Discord bot..."

  begin
    if DiscordBotManagerService.running_or_starting?
      Rails.logger.info "Setting stop signal for bot..."
      DiscordBotManagerService.stop_bot
      sleep 5
      Rails.logger.info "Bot shutdown signal sent"
    end
  rescue => e
    Rails.logger.error "Error during bot shutdown: #{e.message}"
  end

  exit
end
