class DiscordBotManagerService
  class BotAlreadyRunningError < StandardError; end
  class BotNotRunningError < StandardError; end

  @mutex = Mutex.new
  @bot_thread = nil
  @bot_instance = nil
  @should_run = false
  @status = :stopped
  @started_at = nil
  @stopped_at = nil
  @error_message = nil

  class << self
    def start_bot
      thread_id = nil

      @mutex.synchronize do
        # Check status without nested lock
        if [ :running, :starting ].include?(@status) && @bot_thread&.alive?
          raise BotAlreadyRunningError, "Bot is already #{@status}"
        end

        @should_run = true
        @status = :starting
        @started_at = Time.current
        @stopped_at = nil
        @error_message = nil

        # Start bot in a thread
        @bot_thread = Thread.new do
          begin
            @mutex.synchronize do
              @status = :running
            end
            broadcast_status
            broadcast_log("Bot starting...")
            DiscordBotJob.perform_now
          rescue StandardError => e
            @mutex.synchronize do
              @status = :error
              @error_message = e.message
            end
            broadcast_status
            broadcast_log("Error in bot: #{e.message}")
          ensure
            @mutex.synchronize do
              @status = :stopped
              @stopped_at = Time.current
            end
            broadcast_status
          end
        end

        thread_id = @bot_thread.object_id
      end

      broadcast_status
      broadcast_log("Bot started in thread #{thread_id}")

      { success: true, message: "Bot is starting" }
    rescue StandardError => e
      @status = :error
      @error_message = e.message
      broadcast_status
      broadcast_log("Error starting bot: #{e.message}")
      { success: false, message: e.message }
    end

    def stop_bot
      @mutex.synchronize do
        # Check status without nested lock
        unless [ :running, :starting ].include?(@status) && @bot_thread&.alive?
          raise BotNotRunningError, "Bot is not running (current status: #{@status})"
        end

        @should_run = false
      end

      broadcast_log("Initiating graceful bot shutdown...")
      broadcast_log("Stop signal sent - bot will disconnect gracefully")
      { success: true, message: "Bot stop signal sent - graceful shutdown in progress" }
    rescue StandardError => e
      broadcast_log("Error stopping bot: #{e.message}")
      @should_run = false
      { success: false, message: e.message }
    end

    def restart_bot
      if running_or_starting?
        stop_bot
        # Wait for the thread to finish
        unless @bot_thread&.join(10) # Wait up to 10 seconds
          broadcast_log("Bot didn't stop in time, force stopping...")
          force_stop
          sleep 1 # Give force_stop a moment to complete
        end
      end

      start_bot
    rescue StandardError => e
      { success: false, message: e.message }
    end

    def force_stop
      @mutex.synchronize do
        @should_run = false
        @bot_thread&.kill
        @bot_thread = nil
        @status = :stopped
        @stopped_at = Time.current
      end

      broadcast_status
      broadcast_log("Bot forcefully stopped")
      { success: true, message: "Bot forcefully stopped" }
    end

    def status
      @mutex.synchronize do
        {
          status: @status,
          thread_id: @bot_thread&.object_id,
          started_at: @started_at,
          stopped_at: @stopped_at,
          error_message: @error_message,
          uptime: @status == :running && @started_at ? Time.current - @started_at : nil
        }
      end
    end

    def should_run?
      @mutex.synchronize { @should_run }
    end

    def running?
      @mutex.synchronize do
        @status == :running && @bot_thread&.alive?
      end
    end

    def running_or_starting?
      @mutex.synchronize do
        [ :running, :starting ].include?(@status) && @bot_thread&.alive?
      end
    end

    def set_bot_instance(bot)
      @mutex.synchronize do
        @bot_instance = bot
      end
    end

    def register_guild_commands
      bot_instance = nil

      @mutex.synchronize do
        raise BotNotRunningError, "Bot is not running" unless @bot_instance
        bot_instance = @bot_instance
      end

      bot_instance.register_all_commands(guild_only: true)

      { success: true, message: "Guild commands registered" }
    rescue StandardError => e
      broadcast_log("Error registering guild commands: #{e.message}", "error")
      { success: false, message: e.message }
    end

    def register_global_commands
      bot_instance = nil

      @mutex.synchronize do
        raise BotNotRunningError, "Bot is not running" unless @bot_instance
        bot_instance = @bot_instance
      end

      bot_instance.register_all_commands(guild_only: false)

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
