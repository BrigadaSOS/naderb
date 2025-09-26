Dotenv.load

Rails.application.config.x.app.oauth_client_id = ENV["DISCORD_OAUTH_CLIENT_ID"]
Rails.application.config.x.app.oauth_client_secret = ENV["DISCORD_OAUTH_CLIENT_SECRET"]
Rails.application.config.x.app.server_id = ENV.fetch("DISCORD_SERVER_ID")
Rails.application.config.x.app.server_invite_url = ENV.fetch("DISCORD_SERVER_INVITE_URL", "https://discord.gg/ajWm26ADEj")

Rails.application.config.x.discord_bot.token = ENV.fetch("DISCORD_TOKEN")

Rails.application.config.after_initialize do
  DiscordBotJob.perform_later
end
