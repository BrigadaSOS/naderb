class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :trackable, :omniauthable, omniauth_providers: [ :discord ]

  has_many :tags, dependent: :destroy

  def self.from_omniauth(auth)
    Rails.logger.debug "User.from_omniauth called with provider: #{auth.provider}, uid: #{auth.uid}"

    expires_at = Time.at(auth.credentials.expires_at)

    user = where(provider: auth.provider, discord_uid: auth.uid).first_or_create do |new_user|
      new_user.provider = auth.provider
      new_user.discord_uid = auth.uid
      new_user.username = auth.info.name
      new_user.email = auth.info.email
      new_user.password = Devise.friendly_token[0, 20]
      new_user.discord_access_token = auth.credentials.token
      new_user.discord_refresh_token = auth.credentials.refresh_token
      new_user.discord_token_expires_at = expires_at

      Rails.logger.info "New user created with Discord UID: #{auth.uid}"
    end

    if user.persisted?
      user.update!(
        discord_access_token: auth.credentials.token,
        discord_refresh_token: auth.credentials.refresh_token,
        discord_token_expires_at: expires_at
      )
    end

    Rails.logger.info "Successfully processed user #{user.id} (#{user.username}) from Discord OAuth"
    user
  rescue => e
    Rails.logger.error "Error in User.from_omniauth: #{e.message}"
    Rails.logger.debug "Backtrace: #{e.backtrace.join('\n')}"
    raise e
  end

  def has_role?(role_id)
    discord_roles.any? { |role| role["id"] == role_id }
  end

  def has_any_role?(role_ids)
    role_ids.any? { |role_id| has_role?(role_id) }
  end

  def admin_or_mod?
    config_roles = [ Rails.application.config.x.app.server_moderator_role_id, Rails.application.config.x.app.server_admin_role_id ].compact
    has_any_role?(config_roles)
  end

  private

  # Cache user roles in memory for 1 hour
  def discord_roles
    guild_id = Rails.application.config.x.app.server_id
    Rails.cache.fetch("#{guild_id}_#{discord_uid}_discord_roles", expires_in: 1.hour) do
      fetch_discord_roles
    end
  end

  def fetch_discord_roles
    discord_api = DiscordApiService.new(discord_uid: discord_uid)
    discord_api.fetch_user_roles()
  rescue => e
    Rails.logger.error "Failed to fetch Discord roles for UID #{uid}: #{e.message}"
    []
  end
end
