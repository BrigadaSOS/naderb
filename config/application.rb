require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Load environment variables early, before initializers
Dotenv.load

module Nadeshikorb
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # I18n configuration
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.available_locales = [ :es ]
    config.i18n.default_locale = :es
    config.i18n.fallbacks = [ I18n.default_locale ]

    # OAuth configuration for Discord (loaded early for Devise)
    config.x.app.oauth_client_id = ENV.fetch("DISCORD_OAUTH_CLIENT_ID")
    config.x.app.oauth_client_secret = ENV.fetch("DISCORD_OAUTH_CLIENT_SECRET")
    config.x.app.server_id = ENV.fetch("DISCORD_SERVER_ID")
    config.x.app.server_invite_url = ENV.fetch("DISCORD_SERVER_INVITE_URL", "https://discord.gg/ajWm26ADEj")
    config.x.app.server_moderator_role_id = ENV.fetch("DISCORD_SERVER_MODERATOR_ROLE_ID")
    config.x.app.server_admin_role_id = ENV.fetch("DISCORD_SERVER_ADMIN_ROLE_ID")

    config.x.discord_bot.token = ENV.fetch("DISCORD_TOKEN")
  end
end
