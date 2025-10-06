module DiscordApiMock
  # Stub Discord member endpoint with custom roles
  def stub_discord_member(server_id:, user_id: "123456789", roles: [], status: 200)
    response_body = if status == 200
      {
        "roles" => roles,
        "joined_at" => "2024-01-01T00:00:00.000000+00:00",
        "user" => {
          "id" => user_id,
          "username" => "testuser"
        }
      }.to_json
    else
      '{"message": "401: Unauthorized", "code": 0}'
    end

    stub_request(:get, "https://discord.com/api/v10/users/@me/guilds/#{server_id}/member")
      .to_return(
        status: status,
        body: response_body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # Stub Discord guilds endpoint (fallback endpoint)
  def stub_discord_guilds(server_id: Setting.discord_server_id, status: 200, in_server: true)
    response_body = if status == 200 && in_server
      [{ "id" => server_id }].to_json
    elsif status == 200 && !in_server
      [].to_json
    else
      '{"message": "401: Unauthorized", "code": 0}'
    end

    stub_request(:get, "https://discord.com/api/v10/users/@me/guilds")
      .to_return(
        status: status,
        body: response_body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # Stub Discord API failure (both endpoints)
  def stub_discord_api_failure
    stub_discord_member(server_id: Setting.discord_server_id, status: 401)
    stub_discord_guilds(status: 401)
  end

  # Stub successful Discord member response with no roles
  def stub_discord_member_no_roles(server_id: Setting.discord_server_id, user_id: "123456789")
    stub_discord_member(server_id: server_id, user_id: user_id, roles: [])
  end
end

RSpec.configure do |config|
  config.include DiscordApiMock, type: :system
  config.include DiscordApiMock, type: :request
end
