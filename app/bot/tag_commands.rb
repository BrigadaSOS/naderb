module TagCommands
  extend Discordrb::EventContainer
  extend CommandHelpers
  extend Helpers

  include GetHandler
  include CreateHandler
  include EditHandler
  include DeleteHandler
  include RawHandler
  include ListHandler

  # Aggregate command schema from handlers - called lazily by CommandRegistry
  def self.command_schema
    {
      name: "tag",
      description: "Gestiona tags del servidor",
      subcommands: {
        create: CreateHandler.command_schema,
        get: GetHandler.command_schema,
        edit: EditHandler.command_schema,
        delete: DeleteHandler.command_schema,
        raw: RawHandler.command_schema
      }
    }
  end

  # The tags command is separate (not a subcommand)
  def self.tags_command_schema
    ListHandler.command_schema
  end
end
