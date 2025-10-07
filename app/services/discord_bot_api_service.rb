class DiscordBotApiService
  include HTTParty
  BASE_URL = "https://discord.com/api/v10"

  def initialize
    @bot_token = Setting.discord_bot_token
    raise "Discord bot token not configured" if @bot_token.blank?
  end

  # Fetch all roles for the configured guild
  def fetch_guild_roles
    guild_id = Setting.discord_server_id
    return [] if guild_id.blank?

    response = self.class.get("#{BASE_URL}/guilds/#{guild_id}/roles", {
      headers: {
        "Authorization" => "Bot #{@bot_token}",
        "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
      }
    })

    if response.success?
      roles = response.parsed_response
      # Filter out @everyone role and sort by position
      roles.reject { |role| role["name"] == "@everyone" }
           .sort_by { |role| -role["position"] }
    else
      Rails.logger.error "Failed to fetch guild roles: #{response.code} #{response.message}"
      []
    end
  rescue => e
    Rails.logger.error "Discord Bot API error fetching roles: #{e.message}"
    []
  end

  # Register application commands globally
  def register_global_commands
    application_id = Setting.discord_application_id
    return { success: false, message: "Application ID not configured" } if application_id.blank?

    commands = build_command_payloads

    # Bulk register all commands at once
    response = self.class.put("#{BASE_URL}/applications/#{application_id}/commands", {
      headers: {
        "Authorization" => "Bot #{@bot_token}",
        "Content-Type" => "application/json",
        "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
      },
      body: commands.to_json
    })

    if response.success?
      Rails.logger.info "Registered #{commands.size} global commands"
      { success: true, message: "Registered #{commands.size} global commands (may take up to 1 hour to propagate)" }
    else
      Rails.logger.error "Failed to register global commands: #{response.code} #{response.body}"
      { success: false, message: "Failed: #{response.code} - #{response.message}" }
    end
  rescue => e
    Rails.logger.error "Discord Bot API error registering global commands: #{e.message}"
    { success: false, message: e.message }
  end

  # Register application commands for a specific guild
  def register_guild_commands
    application_id = Setting.discord_application_id
    guild_id = Setting.discord_server_id

    return { success: false, message: "Application ID not configured" } if application_id.blank?
    return { success: false, message: "Server ID not configured" } if guild_id.blank?

    commands = build_command_payloads

    # Bulk register all commands at once
    response = self.class.put("#{BASE_URL}/applications/#{application_id}/guilds/#{guild_id}/commands", {
      headers: {
        "Authorization" => "Bot #{@bot_token}",
        "Content-Type" => "application/json",
        "User-Agent" => "DiscordBot (Nadeshikorb, 1.0)"
      },
      body: commands.to_json
    })

    if response.success?
      Rails.logger.info "Registered #{commands.size} guild commands"
      { success: true, message: "Registered #{commands.size} guild commands" }
    else
      Rails.logger.error "Failed to register guild commands: #{response.code} #{response.body}"
      { success: false, message: "Failed: #{response.code} - #{response.message}" }
    end
  rescue => e
    Rails.logger.error "Discord Bot API error registering guild commands: #{e.message}"
    { success: false, message: e.message }
  end

  private

  # Build command payloads from CommandRegistry
  def build_command_payloads
    CommandRegistry.command_definitions.map do |cmd|
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

  # Map parameter types to Discord option types
  def map_parameter_type(type)
    case type.to_s.downcase
    when "string" then 3
    when "number", "integer" then 4
    when "boolean" then 5
    when "user" then 6
    when "channel" then 7
    when "role" then 8
    when "mentionable" then 9
    else 3 # Default to string
    end
  end
end
