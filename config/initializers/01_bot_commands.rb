# Explicitly load bot command modules
# These don't follow Zeitwerk conventions (they're in app/bot/commands/ but not in a Commands namespace)

Rails.application.config.to_prepare do
  # Load command utilities first
  load Rails.root.join('app/bot/commands/helpers.rb')
  load Rails.root.join('app/bot/commands/schema.rb')
  load Rails.root.join('app/bot/commands/registrar.rb')

  # Load tag command helpers and handlers
  load Rails.root.join('app/bot/commands/tag/helpers.rb')
  load Rails.root.join('app/bot/commands/tag/get_handler.rb')
  load Rails.root.join('app/bot/commands/tag/create_handler.rb')
  load Rails.root.join('app/bot/commands/tag/edit_handler.rb')
  load Rails.root.join('app/bot/commands/tag/delete_handler.rb')
  load Rails.root.join('app/bot/commands/tag/list_handler.rb')
  load Rails.root.join('app/bot/commands/tag/raw_handler.rb')

  # Load command modules
  load Rails.root.join('app/bot/commands/tag.rb')
  load Rails.root.join('app/bot/commands/admin.rb')
  load Rails.root.join('app/bot/commands/profile.rb')
end
