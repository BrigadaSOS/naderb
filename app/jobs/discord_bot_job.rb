class DiscordBotJob < ApplicationJob
  queue_as :discord

  # Auto-restart on errors unless manually stopped
  retry_on StandardError, wait: :exponentially_longer, attempts: Float::INFINITY do |_job, error|
    next unless Discord::BotManager.should_run?

    Discord::LogBroadcaster.warn("Bot crashed: #{error.message}. Restarting...")
  end

  def perform
    return unless Discord::BotManager.should_run?

    Discord::LogBroadcaster.info("Starting Discord bot...")

    bot = Discordrb::Bot.new(token: Setting.discord_bot_token, intents: [ :server_messages ])

    # Include command modules
    # bot.include!(AdminCommands)
    # bot.include!(ProfileCommands)
    bot.include!(TagCommands)

    Discord::BotManager.set_bot_instance(bot)

    bot.ready { Discord::LogBroadcaster.info("Bot connected and running") }
    bot.run(:async)

    # Poll for stop signal
    loop do
      break unless Discord::BotManager.should_run?
      sleep 5
    end

    Discord::LogBroadcaster.info("Stopping bot...")
    bot.stop
    Discord::BotManager.send(:clear_bot_ready)
    Discord::LogBroadcaster.info("Bot stopped gracefully")
  rescue StandardError => e
    Discord::LogBroadcaster.error("ERROR: #{e.message}", exception: e)
    bot&.stop rescue nil
    Discord::BotManager.send(:clear_bot_ready)
    raise
  end
end
