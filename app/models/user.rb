class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :trackable, :omniauthable, omniauth_providers: [ :discord ]

  has_many :tags, dependent: :destroy

  enum :role, { regular_user: 0, admin: 1 }, default: :regular_user

  # Alias for convenience
  def user?
    regular_user?
  end

  def discord_only?
    discord_only == true
  end

  def web_enabled?
    !discord_only? && email.present?
  end

  def self.find_or_create_from_discord(discord_uid:, username: nil)
    where(discord_uid: discord_uid).first_or_create do |user|
      user.discord_uid = discord_uid
      user.username = username || "User#{discord_uid}"
      user.provider = "discord_bot"
      user.discord_only = true
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def self.from_omniauth(auth)
    Rails.logger.debug "User.from_omniauth called with provider: #{auth.provider}, uid: #{auth.uid}"

    expires_at = Time.at(auth.credentials.expires_at)

    # First, look for ANY user with this discord_uid (regardless of provider)
    user = where(discord_uid: auth.uid).first

    if user
      if user.discord_only?
        # CLAIM: Convert Discord-only user to full OAuth user
        user.update!(
          provider: auth.provider,
          username: auth.info.name,
          email: auth.info.email,
          discord_access_token: auth.credentials.token,
          discord_refresh_token: auth.credentials.refresh_token,
          discord_token_expires_at: expires_at,
          discord_only: false
        )
        Rails.logger.info "Discord-only user #{user.discord_uid} claimed via OAuth"
      else
        # EXISTING: Just update tokens for existing OAuth user
        user.update!(
          discord_access_token: auth.credentials.token,
          discord_refresh_token: auth.credentials.refresh_token,
          discord_token_expires_at: expires_at
        )
        Rails.logger.info "Updated existing OAuth user #{user.id} tokens"
      end
    else
      # NEW: Create fresh OAuth user
      user = create!(
        provider: auth.provider,
        discord_uid: auth.uid,
        username: auth.info.name,
        email: auth.info.email,
        password: Devise.friendly_token[0, 20],
        discord_access_token: auth.credentials.token,
        discord_refresh_token: auth.credentials.refresh_token,
        discord_token_expires_at: expires_at,
        discord_only: false
      )
      Rails.logger.info "New OAuth user created with Discord UID: #{auth.uid}"
    end

    Rails.logger.info "Successfully processed user #{user.id} (#{user.username}) from Discord OAuth"
    user
  rescue => e
    Rails.logger.error "Error in User.from_omniauth: #{e.message}"
    Rails.logger.debug "Backtrace: #{e.backtrace.join('\n')}"
    raise e
  end

  def has_discord_role?(role_id)
    discord_roles.any? { |role| role["id"] == role_id }
  end

  def has_any_discord_role?(role_ids)
    role_ids.any? { |role_id| has_discord_role?(role_id) }
  end

  def discord_admin?
    has_any_discord_role?(Setting.discord_admin_roles)
  end

  def discord_moderator?
    has_any_discord_role?(Setting.discord_moderator_roles)
  end

  def discord_trusted?
    has_any_discord_role?(Setting.discord_trusted_roles)
  end

  def discord_admin_or_mod?
    discord_admin? || discord_moderator?
  end

  private

  # Cache user roles in memory for 1 hour
  def discord_roles
    guild_id = Setting.discord_server_id
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
