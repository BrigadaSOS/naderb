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
end
