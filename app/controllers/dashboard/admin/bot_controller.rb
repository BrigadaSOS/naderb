class Dashboard::Admin::BotController < ApplicationController
  include WebAuthorization
  before_action :authenticate_user!
  before_action :admin_required!

  def index
    @commands = CommandSchema.to_array
    @bot_status = DiscordBotManagerService.status
  end

  def start
    result = DiscordBotManagerService.start_bot
    render json: result
  rescue DiscordBotManagerService::BotAlreadyRunningError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def stop
    result = DiscordBotManagerService.stop_bot
    render json: result
  rescue DiscordBotManagerService::BotNotRunningError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def restart
    result = DiscordBotManagerService.restart_bot
    render json: result
  end

  def status
    result = DiscordBotManagerService.status
    render json: result
  end

  def force_stop
    result = DiscordBotManagerService.force_stop
    render json: result
  end

  def register_guild_commands
    result = DiscordBotManagerService.register_guild_commands
    render json: result
  rescue DiscordBotManagerService::BotNotRunningError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def register_global_commands
    result = DiscordBotManagerService.register_global_commands
    render json: result
  rescue DiscordBotManagerService::BotNotRunningError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end
end
