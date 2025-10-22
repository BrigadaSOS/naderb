class Dashboard::Admin::ConfigController < ApplicationController
  include WebAuthorization
  before_action :authenticate_user!
  before_action :admin_required!

  def index
    # Load Discord roles for the config form
    @discord_roles = Rails.cache.fetch("discord_guild_roles", expires_in: 1.day) do
      begin
        Discord::Api::BotService.new.fetch_guild_roles
      rescue => e
        Rails.logger.error "Failed to fetch Discord roles: #{e.message}"
        []
      end
    end
  end

  def refresh_discord_roles
    Rails.cache.delete("discord_guild_roles")
    redirect_to dashboard_admin_config_index_path, notice: "Discord roles cache cleared and will be refreshed on next load"
  end

  def update_discord_roles
    Setting.discord_admin_roles = params[:admin_roles] || []
    Setting.discord_moderator_roles = params[:moderator_roles] || []
    Setting.trusted_user_roles = params[:trusted_roles] || []

    redirect_to dashboard_admin_config_index_path, notice: "Discord role configuration updated successfully"
  rescue => e
    redirect_to dashboard_admin_config_index_path, alert: "Failed to update configuration: #{e.message}"
  end
end
