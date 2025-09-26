require "net/http"
require "uri"
require "json"

class DiscordServerVerificationService
  DISCORD_API_BASE = "https://discord.com/api/v10"

  def initialize(access_token)
    @access_token = access_token
  end

  def user_in_required_server?
    return true unless required_server_id.present?

    user_guilds = fetch_user_guilds()
    return false unless user_guilds

    user_guilds.any? { |guild| guild["id"] == required_server_id() }
  end

  def required_server_id
    @required_server_id ||= Rails.application.config.x.app.server_id
  end

  def invite_url
    @invite_url ||= Rails.application.config.x.app.server_invite_url
  end

  private

  def fetch_user_guilds
    uri = URI("#{DISCORD_API_BASE}/users/@me/guilds")

    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request["User-Agent"] = "DiscordBot (Nadeshikorb, 1.0)"

      response = http.request(request)

      return nil unless response.code == "200"

      JSON.parse(response.body)
    end
  rescue => e
    Rails.logger.error "Discord API error: #{e.message}"
    nil
  end
end

