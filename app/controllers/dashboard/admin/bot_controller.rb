class Dashboard::Admin::BotController < ApplicationController
  include WebAuthorization
  before_action :authenticate_user!
  before_action :admin_required!

  def index
    @commands = CommandSchema.to_array
    @bot_status = Discord::BotManager.status
  end

  def start
    result = Discord::BotManager.start_bot
    render json: result
  rescue Discord::BotManager::BotAlreadyRunningError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def stop
    result = Discord::BotManager.stop_bot
    render json: result
  rescue Discord::BotManager::BotNotRunningError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def restart
    result = Discord::BotManager.restart_bot
    render json: result
  end

  def status
    result = Discord::BotManager.status
    render json: result
  end

  def force_stop
    result = Discord::BotManager.force_stop
    render json: result
  end

  def register_guild_commands
    result = Discord::BotManager.register_guild_commands
    render json: result
  rescue Discord::BotManager::BotNotRunningError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end

  def register_global_commands
    result = Discord::BotManager.register_global_commands
    render json: result
  rescue Discord::BotManager::BotNotRunningError => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  end
end
