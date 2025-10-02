class Dashboard::Admin::ConfigController < ApplicationController
  include WebAuthorization
  before_action :authenticate_user!
  before_action :admin_required!

  def index
  end

  def fetch_discord_roles
    bot_service = DiscordBotApiService.new
    roles = bot_service.fetch_guild_roles

    render json: {
      roles: roles.map { |role| { id: role["id"], name: role["name"], color: role["color"] } }
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update_discord_roles
    Setting.discord_admin_roles = params[:admin_roles] || []
    Setting.discord_moderator_roles = params[:moderator_roles] || []
    Setting.discord_trusted_roles = params[:trusted_roles] || []

    redirect_to dashboard_admin_config_index_path, notice: "Discord role configuration updated successfully"
  rescue => e
    redirect_to dashboard_admin_config_index_path, alert: "Failed to update configuration: #{e.message}"
  end

  private

  def admin_required!
    require_admin
  end
end