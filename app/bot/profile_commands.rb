  module ProfileCommands
    extend Discordrb::EventContainer

    application_command(:perfil).subcommand(:info) do |event|
      event.defer(ephemeral: true)

      user = event.options["usuario"]
      event.edit_response(content: "Perfil de: #{user}")
    end

    application_command(:perfil).subcommand(:cumple) do |event|
      event.defer(ephemeral: true)

      event.edit_response(content: "Cumpleaños")
    end
  end
