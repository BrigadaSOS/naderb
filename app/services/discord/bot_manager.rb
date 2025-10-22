module Discord
  class BotManager
  @mutex = Mutex.new
  @bot_instance = nil

  CACHE_KEY = "discord_bot:should_run"
  STARTED_AT_KEY = "discord_bot:started_at"
  BOT_READY_KEY = "discord_bot:ready"

  class << self
    def start_bot
      @mutex.synchronize do
        return { success: false, message: "Bot is already running" } if should_run?

        Rails.cache.write(CACHE_KEY, true)
        Rails.cache.write(STARTED_AT_KEY, Time.current.to_s)
      end

      DiscordBotJob.perform_later
      Discord::LogBroadcaster.info("Bot job queued")

      { success: true, message: "Bot is starting" }
    end

    def stop_bot
      @mutex.synchronize do
        return { success: false, message: "Bot is not running" } unless should_run?

        Rails.cache.write(CACHE_KEY, false)
        Rails.cache.delete(BOT_READY_KEY)
      end

      Discord::LogBroadcaster.info("Stop signal sent - bot will shutdown gracefully")
      { success: true, message: "Bot stop signal sent" }
    end

    def restart_bot
      stop_bot
      sleep 2 # Give bot time to stop
      start_bot
    end

    def should_run?
      Rails.cache.read(CACHE_KEY) || false
    end

    def running_or_starting?
      should_run?
    end

    def set_bot_instance(bot)
      @bot_instance = bot
      Rails.cache.write(BOT_READY_KEY, true, expires_in: 1.hour)
    end

    def bot_ready?
      Rails.cache.read(BOT_READY_KEY) || @bot_instance.present?
    end

    def status
      is_running = should_run?
      started_at = is_running ? Time.parse(Rails.cache.read(STARTED_AT_KEY) || Time.current.to_s) : nil
      {
        status: is_running ? :running : :stopped,
        started_at: started_at,
        uptime: is_running && started_at ? Time.current - started_at : nil
      }
    end

    def register_guild_commands
      # Use Discord HTTP API directly (works across processes, bot doesn't need to be running)
      result = Discord::Api::BotService.new.register_guild_commands
      if result[:success]
        Discord::LogBroadcaster.info(result[:message])
      else
        Discord::LogBroadcaster.error(result[:message])
      end
      result
    rescue StandardError => e
      Discord::LogBroadcaster.error("Error registering guild commands: #{e.message}", exception: e)
      { success: false, message: e.message }
    end

    def register_global_commands
      # Use Discord HTTP API directly (works across processes, bot doesn't need to be running)
      result = Discord::Api::BotService.new.register_global_commands
      if result[:success]
        Discord::LogBroadcaster.info(result[:message])
      else
        Discord::LogBroadcaster.error(result[:message])
      end
      result
    rescue StandardError => e
      Discord::LogBroadcaster.error("Error registering global commands: #{e.message}", exception: e)
      { success: false, message: e.message }
    end

    private

    def clear_bot_ready
      Rails.cache.delete(BOT_READY_KEY)
    end
  end
  end
end
