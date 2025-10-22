# Discord API service for bot-level operations
# Uses bot token for admin-level access to guild resources
module Discord
  module Api
  class BotService < BaseService
    def initialize
      @bot_token = Setting.discord_bot_token
      raise "Discord bot token not configured" if @bot_token.blank?
    end

    # Fetch all roles for the configured guild
    # @return [Array<Hash>] Array of role objects, sorted by position
    def fetch_guild_roles
      guild_id = Setting.discord_server_id
      return [] if guild_id.blank?

      roles = get(
        "/guilds/#{guild_id}/roles",
        headers: bot_headers(@bot_token)
      )

      # Filter out @everyone role and sort by position
      roles.reject { |role| role["name"] == "@everyone" }
           .sort_by { |role| -role["position"] }
    rescue => e
      log_error("Failed to fetch guild roles: #{e.message}", exception: e)
      []
    end

    # Fetch all channels for the configured guild
    # @return [Array<Hash>] Array of channel objects (text and announcement only)
    def fetch_guild_channels
      guild_id = Setting.discord_server_id
      return [] if guild_id.blank?

      channels = get(
        "/guilds/#{guild_id}/channels",
        headers: bot_headers(@bot_token)
      )

      # Filter to text channels (type 0) and announcement channels (type 5)
      channels.select { |channel| [0, 5].include?(channel["type"]) }
              .sort_by { |channel| channel["position"] || 999 }
              .map { |channel| { id: channel["id"], name: channel["name"], type: channel["type"] } }
    rescue => e
      log_error("Failed to fetch guild channels: #{e.message}", exception: e)
      []
    end

    # Send a message to a Discord channel
    # @param channel_id [String] The Discord channel ID
    # @param content [String] The message content
    # @return [Hash] { success: Boolean, message_id: String (if success), error: String (if failed) }
    def send_message(channel_id, content)
      response_data = post(
        "/channels/#{channel_id}/messages",
        headers: bot_headers(@bot_token),
        body: { content: content }
      )

      { success: true, message_id: response_data["id"] }
    rescue ApiError => e
      log_error("Failed to send Discord message: #{e.message}")
      { success: false, error: "API Error", message: e.message }
    rescue => e
      log_error("Unexpected error sending message: #{e.message}", exception: e)
      { success: false, error: e.class.name, message: e.message }
    end

    # Register application commands globally
    # @return [Hash] { success: Boolean, message: String }
    def register_global_commands
      application_id = Setting.discord_application_id
      return { success: false, message: "Application ID not configured" } if application_id.blank?

      commands = build_command_payloads

      put(
        "/applications/#{application_id}/commands",
        headers: bot_headers(@bot_token),
        body: commands
      )

      Rails.logger.info "Registered #{commands.size} global commands"
      { success: true, message: "Registered #{commands.size} global commands (may take up to 1 hour to propagate)" }
    rescue => e
      log_error("Failed to register global commands: #{e.message}", exception: e)
      { success: false, message: e.message }
    end

    # Register application commands for a specific guild
    # @return [Hash] { success: Boolean, message: String }
    def register_guild_commands
      application_id = Setting.discord_application_id
      guild_id = Setting.discord_server_id

      return { success: false, message: "Application ID not configured" } if application_id.blank?
      return { success: false, message: "Server ID not configured" } if guild_id.blank?

      commands = build_command_payloads

      put(
        "/applications/#{application_id}/guilds/#{guild_id}/commands",
        headers: bot_headers(@bot_token),
        body: commands
      )

      Rails.logger.info "Registered #{commands.size} guild commands"
      { success: true, message: "Registered #{commands.size} guild commands" }
    rescue => e
      log_error("Failed to register guild commands: #{e.message}", exception: e)
      { success: false, message: e.message }
    end

    private

    # Build command payloads from CommandSchema
    # @return [Array<Hash>] Array of command definitions
    def build_command_payloads
      CommandSchema.to_array.map do |cmd|
        payload = {
          name: cmd[:name],
          description: cmd[:description],
          type: 1 # CHAT_INPUT
        }

        # Add options (parameters or subcommands)
        options = []

        if cmd[:subcommands].present?
          # Command has subcommands
          options = cmd[:subcommands].map do |sub|
            {
              type: 1, # SUB_COMMAND
              name: sub[:name],
              description: sub[:description],
              options: build_options(sub[:parameters])
            }
          end
        elsif cmd[:parameters].present?
          # Command has direct parameters
          options = build_options(cmd[:parameters])
        end

        payload[:options] = options if options.any?
        payload
      end
    end

    # Build options array from parameters
    # @param parameters [Hash, nil] Parameters hash
    # @return [Array<Hash>] Array of option definitions
    def build_options(parameters)
      return [] if parameters.blank?

      parameters.map do |param|
        option = {
          type: map_parameter_type(param[:type]),
          name: param[:name],
          description: param[:description],
          required: param[:required] || false
        }

        option[:autocomplete] = true if param[:autocomplete]
        option
      end
    end

    # Map parameter type to Discord API type code
    # @param type [String, Symbol] Parameter type
    # @return [Integer] Discord API type code
    def map_parameter_type(type)
      case type.to_s.downcase
      when "string" then 3
      when "number", "integer" then 4
      when "boolean" then 5
      when "user" then 6
      when "channel" then 7
      when "role" then 8
      when "mentionable" then 9
      when "attachment" then 11
      else 3 # Default to string
      end
    end
  end
end
end
