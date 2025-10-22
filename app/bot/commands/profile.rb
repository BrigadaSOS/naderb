module ProfileCommands
  extend Discordrb::EventContainer
  extend CommandHelpers

  def self.command_schema
    {
      name: "perfil",
      description: "Modifica un perfil",
      subcommands: {
        info: {
          name: "info",
          description: "Muestra información del perfil de un usuario",
          parameters: {
            user: { name: "usuario", type: "user", required: true, description: "Usuario a mostrar" }
          }
        },
        birthday: {
          name: "cumple",
          description: "Configura tu fecha de cumple",
          parameters: {
            day: { name: "dia", type: "number", required: true, description: "Día del mes (1-31)" },
            month: { name: "mes", type: "string", required: true, description: "Mes del año (1-12)" }
          }
        }
      }
    }
  end

  # Register info subcommand
  define_subcommand(:perfil, command_schema[:subcommands][:info]) do |event|
    event.defer(ephemeral: true)
    params = extract_params_from_event(command_schema[:subcommands][:info], event)
    event.edit_response(content: "Perfil de: #{params[:user]}")
  end

  # Register birthday subcommand
  define_subcommand(:perfil, command_schema[:subcommands][:birthday]) do |event|
    event.defer(ephemeral: true)
    params = extract_params_from_event(command_schema[:subcommands][:birthday], event)
    event.edit_response(content: "Cumpleaños: #{params[:day]}/#{params[:month]}")
  end
end
