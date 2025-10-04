class User < ApplicationRecord
  # Include default devise modules. Others available are:
  devise :database_authenticatable, :trackable, :omniauthable, omniauth_providers: [ :discord ]

  # Use uuid v7
  attribute :id, :uuid_v7, default: -> { SecureRandom.uuid_v7 }

  has_many :tags, dependent: :destroy

  def self.find_or_create_from_discord(discord_uid:, discord_user: nil)
    where(discord_uid: discord_uid).first_or_create do |user|
      user.provider = "discord_bot"
      user.discord_uid = discord_uid
      user.username = discord_user.username
      user.display_name = discord_user.global_name
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def self.from_omniauth(auth)
    Rails.logger.debug "User.from_omniauth called with provider: #{auth.provider}, uid: #{auth.uid}"
    Rails.logger.debug "ID: #{Setting.discord_server_id}"

    auth_attributes = {
      provider: auth.provider,
      username: auth.info.name,
      display_name: auth.dig(:extra, :raw_info, :global_name) || username,
      email: auth.info.email,
      discord_access_token: auth.credentials.token,
      discord_refresh_token: auth.credentials.refresh_token,
      discord_token_expires_at: Time.at(auth.credentials.expires_at),
      profile_image_url: auth.info.image
    }

    user = find_or_initialize_by(discord_uid: auth.uid)

    if user.persisted?
      user.update!(auth_attributes)
      Rails.logger.info "Updated existing user #{user.discord_uid} claimed via OAuth"
    else
      new_user_attributes = {
        discord_uid: auth.uid,
        password: Devise.friendly_token[0, 20]
      }
      user.assign_attributes(auth_attributes.merge(new_user_attributes))
      user.save!
      Rails.logger.info "New OAuth user created with Discord UID: #{auth.uid}"
    end

    Rails.logger.info "Successfully processed user #{user.id} (#{user.username}) from Discord OAuth"
    user
  rescue => e
    Rails.logger.error "Error in User.from_omniauth: #{e.message}"
    raise e
  end

  def name
    display_name.presence || username || email || "User #{id}"
  end

  def admin_or_mod?(impersonated_roles: nil)
    admin?(impersonated_roles: impersonated_roles) || moderator?(impersonated_roles: impersonated_roles)
  end

  def admin?(impersonated_roles: nil)
    has_any_discord_role?(Setting.discord_admin_roles, impersonated_roles: impersonated_roles)
  end

  def moderator?(impersonated_roles: nil)
    has_any_discord_role?(Setting.discord_moderator_roles, impersonated_roles: impersonated_roles)
  end

  def trusted_user?(impersonated_roles: nil)
    has_any_discord_role?(Setting.trusted_user_roles, impersonated_roles: impersonated_roles)
  end

  def has_discord_role?(role_id, impersonated_roles: nil)
    discord_roles(impersonated_roles: impersonated_roles).any? { |role| role["id"] == role_id }
  end

  def has_any_discord_role?(role_ids, impersonated_roles: nil)
    role_ids.any? { |role_id| has_discord_role?(role_id, impersonated_roles: impersonated_roles) }
  end

  private

  # Cache user roles in memory for 1 hour
  def discord_roles(impersonated_roles: nil)
    # In development, allow role impersonation
    if Rails.env.development? && impersonated_roles.present?
      return impersonated_roles.map { |role_id| { "id" => role_id } }
    end

    guild_id = Setting.discord_server_id
    Rails.cache.fetch("#{guild_id}_#{discord_uid}_discord_roles", expires_in: 1.days) do
      fetch_discord_roles
    end
  end

  def fetch_discord_roles
    begin
      discord_api = DiscordApiService.new(discord_uid: discord_uid)
      discord_api.fetch_member_info()
    rescue => e
      Rails.logger.error "Failed to fetch Discord roles for UID #{uid}: #{e.message}"
        []
    end
  end
end
