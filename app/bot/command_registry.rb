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

    bot.register_application_command(:tag, "Gestiona tags del servidor", server_id: server_id) do |cmd|
      cmd.subcommand(:create, "Crea un nuevo tag") do |sub|
        sub.string("name", "Nombre del tag", required: true)
        sub.string("content", "Contenido del tag", required: true)
      end

      cmd.subcommand(:get, "Obtiene un tag existente") do |sub|
        sub.string("name", "Nombre del tag", required: true)
      end

      cmd.subcommand(:edit, "Edita un tag existente") do |sub|
        sub.string("name", "Nombre del tag actual", required: true)
        sub.string("content", "Nuevo contenido del tag", required: true)
        sub.string("new_name", "Nuevo nombre del tag (opcional)", required: false)
      end

      cmd.subcommand(:delete, "Elimina un tag") do |sub|
        sub.string("name", "Nombre del tag a eliminar", required: true)
      end

      cmd.subcommand(:raw, "Obtiene el contenido crudo de un tag") do |sub|
        sub.string("name", "Nombre del tag", required: true)
      end
    end

    bot.register_application_command(:tags, "Lista todos los tags del servidor", server_id: server_id) do |option|
      option.string("search", "Buscar tags por nombre (opcional)", required: false)
    end
  end
end
