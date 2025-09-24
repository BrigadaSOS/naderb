class CommandRegistry
  def self.register_commands(bot)
    server_id = ENV["GUILD_ID"] || nil
    Rails.logger.info "Using server ID: #{server_id}"

    bot.register_application_command(:hora, "Muestra la hora", server_id: server_id) do |option|
      option.string("zona_horaria", "La zona horaria en la que mostrar la hora", autocomplete: true)
    end

    bot.register_application_command(:perfil, "Modifica un perfil", server_id: server_id) do |cmd|
      cmd.subcommand(:info, "Muestra información del perfil de un usuario") do |sub|
        sub.user("usuario", "Usuario a mostrar", required: true)
      end

      cmd.subcommand(:cumple, "Configura tu fecha de cumple") do |sub|
        sub.number("dia", "Día del mes (1-31)", required: true)
        sub.string("mes", "Mes del año (1-12)", required: true)
      end
    end
  end
end
