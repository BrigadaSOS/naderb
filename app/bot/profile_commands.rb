  module ProfileCommands
    extend Discordrb::EventContainer
    extend CommandRegistry::Helpers

    define_subcommand(:profile, :info) do | event, params |
      event.defer(ephemeral: true)
      event.edit_response(content: "Perfil de: #{params[:user]}")
    end

    define_subcommand(:profile, :birthday) do | event, params |
      event.defer(ephemeral: true)
      event.edit_response(content: "Cumpleaños")
    end
  end
