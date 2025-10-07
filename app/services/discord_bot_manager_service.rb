class DiscordBotManagerService
  @mutex = Mutex.new
  @bot_instance = nil
  @should_run = false
  @started_at = nil

  class << self
    def start_bot
      @mutex.synchronize do
        return { success: false, message: "Bot is already running" } if @should_run

        @should_run = true
        @started_at = Time.current
      end

      DiscordBotJob.perform_later
      broadcast_log("Bot job queued")

      { success: true, message: "Bot is starting" }
    end

    def stop_bot
      @mutex.synchronize do
        return { success: false, message: "Bot is not running" } unless @should_run

        @should_run = false
      end

      broadcast_log("Stop signal sent - bot will shutdown gracefully")
      { success: true, message: "Bot stop signal sent" }
    end

    def restart_bot
      stop_bot
      sleep 2 # Give bot time to stop
      start_bot
    end

    def should_run?
      @should_run
    end

    def running_or_starting?
      should_run?
    end

    def set_bot_instance(bot)
      @bot_instance = bot
    end

    def status
      is_running = should_run?
      {
        status: is_running ? :running : :stopped,
        started_at: is_running ? @started_at : nil,
        uptime: is_running && @started_at ? Time.current - @started_at : nil
      }
    end

    def register_guild_commands
      return { success: false, message: "Bot is not running" } unless @bot_instance

      CommandRegistry.register_all_commands(@bot_instance, guild_only: true)
      { success: true, message: "Guild commands registered" }
    rescue StandardError => e
      broadcast_log("Error registering guild commands: #{e.message}", "error")
      { success: false, message: e.message }
    end

    def register_global_commands
      return { success: false, message: "Bot is not running" } unless @bot_instance

      CommandRegistry.register_all_commands(@bot_instance, guild_only: false)
      { success: true, message: "Global commands registered (may take up to 1 hour to propagate)" }
    rescue StandardError => e
      broadcast_log("Error registering global commands: #{e.message}", "error")
      { success: false, message: e.message }
    end

    private

    def broadcast_log(message, level = "info")
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

    def broadcast_status
      ActionCable.server.broadcast(
        "bot_updates",
        {
          type: "status",
          status: status
        }
      )
    rescue => e
      Rails.logger.debug("Failed to broadcast status: #{e.message}")
    end
  end
end
