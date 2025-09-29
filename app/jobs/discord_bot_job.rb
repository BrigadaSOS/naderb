require "discordrb"
require "dotenv"

class DiscordBotJob < ApplicationJob
  queue_as :discord
  retry_on StandardError, wait: 2.seconds, attempts: 3

  class BotInitializationError < StandardError; end
  class BotConnectionError < StandardError; end

  def perform(*args)
    Dotenv.load

    logger.info "Starintg Discord bot..."

    begin
      token = Rails.application.config.x.discord_bot.token

      bot = Discordrb::Bot.new(token: token, intents: [ :server_messages ])

      CommandRegistry.register_commands(bot)

      bot.include!(AdminCommands)
      bot.include!(ProfileCommands)
      bot.include!(TagCommands)

      bot.run
    raise StandardError => e
      logger.error "Unexpected error initializing Discord bot: #{e.message}"
      raise
    end
  end
end
