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
      Rails.application.credentials.discord[:token]
    end

    def discord_application_id
      Rails.application.credentials.discord[:oauth_client_id]
    end

    def discord_oauth_client_id
      Rails.application.credentials.discord[:oauth_client_id]
    end

    def discord_oauth_client_secret
      Rails.application.credentials.discord[:oauth_client_secret]
    end

    # Sync credentials to DB on initialization
    def sync_from_credentials!
      discord = Rails.application.credentials.discord
      return unless discord

      self.discord_server_id = discord[:server_id] if discord[:server_id].present?
      self.discord_server_invite_url = discord[:server_invite_url] if discord[:server_invite_url].present?
      self.discord_admin_roles = Array(discord[:admin_role_ids]) if discord[:admin_role_ids].present?
      self.discord_moderator_roles = Array(discord[:moderator_role_ids]) if discord[:moderator_role_ids].present?
      self.trusted_user_roles = Array(discord[:trusted_role_ids]) if discord[:trusted_role_ids].present?

      Rails.logger.info "Discord settings synced from Rails credentials"
    end
  end
end
