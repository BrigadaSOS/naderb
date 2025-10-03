# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  # Discord server configuration
  field :discord_server_id, type: :string, validates: { presence: true }
  field :discord_server_invite_url, type: :string, validates: { presence: true }

  # Discord role configurations
  field :discord_admin_roles, type: :array, default: [], validates: { presence: true }
  field :discord_moderator_roles, type: :array, default: [], validates: { presence: true }
  field :discord_trusted_roles, type: :array, default: [], validates: { presence: true }

  # Sensitive values - read directly from ENV, never stored in DB
  class << self
    def discord_bot_token
      ENV["DISCORD_TOKEN"]
    end

    def discord_application_id
      ENV["DISCORD_APPLICATION_ID"]
    end

    def discord_oauth_client_id
      ENV["DISCORD_OAUTH_CLIENT_ID"]
    end

    def discord_oauth_client_secret
      ENV["DISCORD_OAUTH_CLIENT_SECRET"]
    end

    # Sync ENV vars to DB on initialization
    def sync_from_env!
      # Server configuration
      if ENV["DISCORD_SERVER_ID"].present?
        self.discord_server_id = ENV["DISCORD_SERVER_ID"]
      end

      if ENV["DISCORD_SERVER_INVITE_URL"].present?
        self.discord_server_invite_url = ENV["DISCORD_SERVER_INVITE_URL"]
      end

      # Role configurations
      if ENV["DISCORD_ADMIN_ROLE_IDS"].present?
        self.discord_admin_roles = ENV["DISCORD_ADMIN_ROLE_IDS"].split(",").map(&:strip).reject(&:blank?)
      end

      if ENV["DISCORD_MODERATOR_ROLE_IDS"].present?
        self.discord_moderator_roles = ENV["DISCORD_MODERATOR_ROLE_IDS"].split(",").map(&:strip).reject(&:blank?)
      end

      if ENV["DISCORD_TRUSTED_ROLE_IDS"].present?
        self.discord_trusted_roles = ENV["DISCORD_TRUSTED_ROLE_IDS"].split(",").map(&:strip).reject(&:blank?)
      end

      Rails.logger.info "Discord settings synced from environment variables"
    end
  end
end
