module Users
  module DiscordAuthenticatable
    extend ActiveSupport::Concern

    class_methods do
      def find_or_create_from_discord(discord_uid:, discord_user: nil)
        where(discord_uid: discord_uid).first_or_create do |user|
          user.provider = "discord_bot"
          user.discord_uid = discord_uid
          user.username = discord_user.username
          user.display_name = discord_user.global_name
          user.password = Devise.friendly_token[0, 20]
        end
      end

      def from_omniauth(auth)
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
    end
  end
end
