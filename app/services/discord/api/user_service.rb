# Discord API service for user-level operations
# Uses user OAuth access token for member-specific operations
module Discord
  module Api
  class UserService < BaseService
    def initialize(user)
      @user = user
      refresh_token_if_needed
    end

    # Check if user is in the required Discord server
    # @return [Boolean] True if user is a member of the server
    def user_in_required_server?
      guilds = fetch_user_guilds
      return false unless guilds

      required_server_id = Setting.discord_server_id.to_s
      guilds.any? { |guild| guild["id"] == required_server_id }
    end

    # Fetch member info including roles for the user in the configured guild
    # @return [Array<Hash>] Array of role objects with IDs
    def fetch_member_info
      required_server_id = Setting.discord_server_id.to_s

      # Try direct member endpoint first (requires guilds.members.read scope)
      member_data = fetch_member_direct(required_server_id)
      return member_data if member_data

      # Fallback to permissions-based check
      fetch_member_from_guilds(required_server_id)
    end

    private

    # Fetch user's guilds
    # @return [Array<Hash>, nil] Array of guild objects or nil on error
    def fetch_user_guilds
      guilds = get(
        "/users/@me/guilds",
        headers: user_headers(user_valid_access_token)
      )

      if Rails.env.development?
        Rails.logger.info "=== USER GUILDS RESPONSE ==="
        Rails.logger.info "User #{@user.discord_uid} is in #{guilds.length} servers:"
        guilds.each do |guild|
          Rails.logger.info "  - #{guild['name']} (ID: #{guild['id']})"
        end
        Rails.logger.info "============================"
      end

      guilds
    rescue => e
      log_error("Failed to fetch user guilds: #{e.message}", exception: e)
      nil
    end

    # Fetch member data using the direct member endpoint
    # @param guild_id [String] Guild ID
    # @return [Array<Hash>, nil] Array of role objects or nil if failed
    def fetch_member_direct(guild_id)
      member_data = get(
        "/users/@me/guilds/#{guild_id}/member",
        headers: user_headers(user_valid_access_token)
      )

      role_ids = member_data["roles"] || []

      # Store the Discord join date if available
      if member_data["joined_at"].present?
        joined_at = Time.parse(member_data["joined_at"])
        @user.update_column(:discord_joined_at, joined_at) if @user.discord_joined_at.nil? || @user.discord_joined_at != joined_at
      end

      Rails.logger.info "Found #{role_ids.length} roles for user in guild #{guild_id}"

      # Return role objects with IDs
      role_ids.map { |role_id| { "id" => role_id, "name" => "Role_#{role_id}" } }
    rescue ApiError => e
      Rails.logger.warn "Member endpoint failed (#{e.message}), falling back to permissions check"
      nil
    end

    # Fetch member data from guilds list (fallback method)
    # @param guild_id [String] Guild ID
    # @return [Array<Hash>] Array of role objects based on permissions
    def fetch_member_from_guilds(guild_id)
      guilds = get(
        "/users/@me/guilds",
        headers: user_headers(user_valid_access_token)
      )

      target_guild = guilds.find { |guild| guild["id"] == guild_id }

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

      Rails.logger.error "Could not fetch member info from guilds"
      []
    rescue => e
      log_error("Failed to fetch member info from guilds: #{e.message}", exception: e)
      []
    end

    # Refresh the user's OAuth access token if needed
    # @return [String, nil] New access token or nil if refresh failed
    def refresh_token
      return unless @user.discord_refresh_token

      response_data = post(
        "/oauth2/token",
        headers: { "Content-Type" => "application/x-www-form-urlencoded" },
        body: {
          client_id: Rails.application.credentials.discord[:client_id],
          client_secret: Rails.application.credentials.discord[:client_secret],
          grant_type: "refresh_token",
          refresh_token: @user.discord_refresh_token
        }
      )

      @user.update!(
        discord_access_token: response_data["access_token"],
        discord_refresh_token: response_data["refresh_token"],
        discord_token_expires_at: Time.current + response_data["expires_in"].seconds
      )

      @user.discord_access_token
    rescue => e
      log_error("Failed to refresh Discord token: #{e.message}", exception: e)
      nil
    end

    # Refresh token if needed before making requests
    def refresh_token_if_needed
      if token_expired? || token_expires_soon?
        refresh_token
      end
    end

    # Get valid access token (may refresh if expired)
    # @return [String] Valid access token
    def user_valid_access_token
      @user.discord_access_token
    end

    # Check if token is expired
    # @return [Boolean] True if token is expired
    def token_expired?
      @user.discord_token_expires_at && @user.discord_token_expires_at < Time.current
    end

    # Check if token expires soon
    # @param threshold [ActiveSupport::Duration] Time threshold
    # @return [Boolean] True if token expires within threshold
    def token_expires_soon?(threshold = 1.day)
      @user.discord_token_expires_at && @user.discord_token_expires_at < (Time.current + threshold)
    end
  end
end
end
