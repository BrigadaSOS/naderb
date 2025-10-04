class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  # Discord server configuration
  field :discord_server_id, type: :string, validates: { presence: true }
  field :discord_server_invite_url, type: :string, validates: { presence: true }

  # Discord role configurations
  field :discord_admin_roles, type: :array, default: [], validates: { presence: true }
  field :discord_moderator_roles, type: :array, default: [], validates: { presence: true }
  field :trusted_user_roles, type: :array, default: [], validates: { presence: true }

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
      sync_field(:discord_server_id, "DISCORD_SERVER_ID")
      sync_field(:discord_server_invite_url, "DISCORD_SERVER_INVITE_URL")
      sync_array_field(:discord_admin_roles, "DISCORD_ADMIN_ROLE_IDS")
      sync_array_field(:discord_moderator_roles, "DISCORD_MODERATOR_ROLE_IDS")
      sync_array_field(:trusted_user_roles, "DISCORD_TRUSTED_ROLE_IDS")

      Rails.logger.info "Discord settings synced from environment variables"
    end

    private

    def sync_field(field_name, env_key)
      value = ENV[env_key]
      send("#{field_name}=", value) if value.present?
    end

    def sync_array_field(field_name, env_key)
      value = ENV[env_key]
      if value.present?
        send("#{field_name}=", value.split(",").map(&:strip).reject(&:blank?))
      end
    end
  end
end
