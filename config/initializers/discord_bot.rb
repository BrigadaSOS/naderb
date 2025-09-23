Rails.application.config.after_initialize do
  DiscordBotJob.perform_later
end
