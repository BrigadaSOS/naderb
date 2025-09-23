module ProfileCommands
  extend Discordrb::EventContainer

  application_command(:perfil).subcommand(:info) do |event|
    event.defer()

    user = event.options["usuario"]
    event.edit_response(content: "Perfil de: #{user}")
  end

  application_command(:perfil).subcommand(:cumple) do |event|
    event.defer()

    event.edit_response(content: "Cumpleanyos")
  end
end
