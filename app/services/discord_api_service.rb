class DiscordApiService
  include HTTParty
  BASE_URL = "https://discord.com/api/v10"

  debug_output $stdout

  def initialize(discord_uid:)
    @user = User.find_by(discord_uid: discord_uid)
  end

  def user_in_required_server?
    user_guilds = fetch_user_guilds()
    return false unless user_guilds

    required_server_id = Setting.discord_server_id
    user_guilds.any? { |guild| guild["id"] == required_server_id }
  end

  def fetch_user_roles
    required_server_id = Setting.discord_server_id

    # Use the guilds.members.read scope endpoint to get user's member info in the specific guild
    member_response = self.class.get("#{BASE_URL}/users/@me/guilds/#{required_server_id}/member", {
      headers: {
        "Authorization" => "Bearer #{user_valid_access_token}",
        "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
      }
    })

    if member_response.success?
      member_data = member_response.parsed_response
      role_ids = member_data["roles"] || []

      # Store the Discord join date if available
      if member_data["joined_at"].present?
        joined_at = Time.parse(member_data["joined_at"])
        @user.update_column(:discord_joined_at, joined_at) if @user.discord_joined_at.nil? || @user.discord_joined_at != joined_at
      end

      Rails.logger.info "Found #{role_ids.length} roles for user in guild #{required_server_id}"

      # Return role objects with IDs
      # Note: We get role IDs but not role names from this endpoint
      # For role names, we'd need bot permissions to call /guilds/{guild.id}/roles
      return role_ids.map { |role_id| { "id" => role_id, "name" => "Role_#{role_id}" } }
    else
      # If the guilds.members.read endpoint fails, fall back to permissions-based check
      Rails.logger.warn "Member endpoint failed (#{member_response.code}), falling back to permissions check"

      guilds_response = self.class.get("#{BASE_URL}/users/@me/guilds", {
        headers: {
          "Authorization" => "Bearer #{user_valid_access_token}",
          "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
        }
      })

      if guilds_response.success?
        guilds = guilds_response.parsed_response
        target_guild = guilds.find { |guild| guild["id"] == required_server_id }

        if target_guild && target_guild["permissions"]
          permissions = target_guild["permissions"].to_i
          roles = []

          # Check for admin permissions (0x8 = ADMINISTRATOR)
          if (permissions & 0x8) != 0
            roles << { "id" => "admin", "name" => "Administrator" }
          end

          # Check for manage guild permissions (0x20 = MANAGE_GUILD)
          if (permissions & 0x20) != 0
            roles << { "id" => "manager", "name" => "Manager" }
          end

          return roles
        end
      end
    end

    Rails.logger.error "Failed to fetch user roles: #{member_response.code} #{member_response.message}"
    []
  rescue => e
    Rails.logger.error "Discord API error fetching roles: #{e.message}"
    []
  end

  private

  def fetch_user_guilds
    response = self.class.get("#{BASE_URL}/users/@me/guilds", {
      headers: {
        "Authorization" => "Bearer #{user_valid_access_token}",
        "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
      }
    })

    if response.success?
      response.parsed_response
    else
      Rails.logger.error "Failed to fetch user guilds: #{response.code} #{response.message}"
      nil
    end
  rescue => e
    Rails.logger.error "Discord API error: #{e.message}"
    nil
  end

  def refresh_token
    return unless @user.discord_refresh_token

    response = self.class.post("#{BASE_URL}/oauth2/token", {
      body: {
        client_id: Rails.application.credentials.discord[:client_id],
        client_secret: Rails.application.credentials.discord[:client_secret],
        grant_type: "refresh_token",
        refresh_token: @user.discord_refresh_token
      },
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded"
      }
    })

    if response.success?
      token_data = response.parsed_response
      @user.update!(
        discord_access_token: token_data["access_token"],
        discord_refresh_token: token_data["refresh_token"],
        discord_token_expires_at: Time.current + token_data["expires_in"].seconds
      )
      @user.discord_access_token
    else
      nil
    end
  rescue => e
    Rails.logger.error "Exception refreshing Discord token: #{e.message}"
    nil
  end

  private

  def user_valid_access_token
    if token_expired? || token_expires_soon?
      refresh_token
    end

    @user.discord_access_token
  end

  def token_expired?
    @user.discord_token_expires_at && @user.discord_token_expires_at < Time.current
  end

  def token_expires_soon?(threshold = 1.day)
    @user.discord_token_expires_at && @user.discord_token_expires_at < (Time.current + threshold)
  end
end
