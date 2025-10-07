module DiscordSettings
  def setup_discord_settings(
    server_id: "999888777",
    admin_roles: [ "123456" ],
    moderator_roles: [ "789012" ],
    trusted_user_roles: [ "654321" ],
    invite_url: "https://discord.gg/test"
  )
    Setting.discord_server_id = server_id
    Setting.discord_admin_roles = admin_roles
    Setting.discord_moderator_roles = moderator_roles
    Setting.trusted_user_roles = trusted_user_roles
    Setting.discord_server_invite_url = invite_url
  end
end

RSpec.configure do |config|
  config.include DiscordSettings, type: :system
  config.include DiscordSettings, type: :request
end
