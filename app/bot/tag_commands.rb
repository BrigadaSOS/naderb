module TagCommands
  extend Discordrb::EventContainer

  application_command(:tag).subcommand(:create) do |event|
    event.defer(ephemeral: true)

    name = event.options["name"]
    content = event.options["content"]
    discord_uid = event.user.id.to_s

    begin
      # Find or create Discord-only user
      user = User.find_or_create_from_discord(
        discord_uid: discord_uid,
        username: event.user.username
      )

      # Create tag using TagsService
      tags_service = TagsService.new(user)
      result = tags_service.create_tag(name: name, content: content)

      if result[:success]
        event.edit_response(content: "✅ Tag `#{result[:tag].name}` creado exitosamente")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error creando tag: #{errors}")
      end
    rescue => e
      Rails.logger.error "Error in tag create command: #{e.message}"
      event.edit_response(content: "❌ Error inesperado creando tag. Inténtalo de nuevo.")
    end
  end

  application_command(:tag).subcommand(:get) do |event|
    name = event.options["name"]

    begin
      tag = Tag.find_by_name(name)

      if tag
        if tag.image_url?
          event.respond(content: tag.content)
        else
          event.respond(content: "**#{tag.name}**: #{tag.content}")
        end
      else
        event.respond(content: "❌ Tag `#{name}` no encontrado", ephemeral: true)
      end
    rescue => e
      Rails.logger.error "Error in tag get command: #{e.message}"
      event.respond(content: "❌ Error obteniendo tag. Inténtalo de nuevo.", ephemeral: true)
    end
  end

  application_command(:tag).subcommand(:edit) do |event|
    event.defer(ephemeral: true)

    name = event.options["name"]
    content = event.options["content"]
    new_name = event.options["new_name"]
    discord_uid = event.user.id.to_s

    begin
      # Find Discord-only user
      user = User.find_by(discord_uid: discord_uid)
      if user.nil?
        event.edit_response(content: "❌ Usuario no encontrado. Debes crear un tag primero.")
        next
      end

      tag = Tag.find_by_name(name)
      if tag.nil?
        event.edit_response(content: "❌ Tag `#{name}` no encontrado")
        next
      end

      # Check if user owns the tag or is admin/mod
      unless tag.user == user || user.admin_or_mod?
        event.edit_response(content: "❌ Solo puedes editar tus propios tags")
        next
      end

      # Update tag using TagsService
      tags_service = TagsService.new(user)
      update_params = { content: content }
      update_params[:name] = new_name if new_name.present?

      result = tags_service.update_tag(tag, update_params)

      if result[:success]
        updated_name = result[:tag].name
        event.edit_response(content: "✅ Tag `#{updated_name}` actualizado exitosamente")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error actualizando tag: #{errors}")
      end
    rescue => e
      Rails.logger.error "Error in tag edit command: #{e.message}"
      event.edit_response(content: "❌ Error inesperado actualizando tag. Inténtalo de nuevo.")
    end
  end

  application_command(:tag).subcommand(:delete) do |event|
    event.defer(ephemeral: true)

    name = event.options["name"]
    discord_uid = event.user.id.to_s

    begin
      # Find Discord-only user
      user = User.find_by(discord_uid: discord_uid)
      if user.nil?
        event.edit_response(content: "❌ Usuario no encontrado")
        next
      end

      tag = Tag.find_by_name(name)
      if tag.nil?
        event.edit_response(content: "❌ Tag `#{name}` no encontrado")
        next
      end

      # Check if user owns the tag or is admin/mod
      unless tag.user == user || user.admin_or_mod?
        event.edit_response(content: "❌ Solo puedes eliminar tus propios tags")
        next
      end

      # Delete tag using TagsService
      tags_service = TagsService.new(user)
      result = tags_service.destroy_tag(tag)

      if result[:success]
        event.edit_response(content: "✅ Tag `#{name}` eliminado exitosamente")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error eliminando tag: #{errors}")
      end
    rescue => e
      Rails.logger.error "Error in tag delete command: #{e.message}"
      event.edit_response(content: "❌ Error inesperado eliminando tag. Inténtalo de nuevo.")
    end
  end

  application_command(:tag).subcommand(:raw) do |event|
    name = event.options["name"]

    begin
      tag = Tag.find_by_name(name)

      if tag
        # Wrap content in code block for raw display
        raw_content = "```\n#{tag.content}\n```"
        event.respond(content: raw_content)
      else
        event.respond(content: "❌ Tag `#{name}` no encontrado", ephemeral: true)
      end
    rescue => e
      Rails.logger.error "Error in tag raw command: #{e.message}"
      event.respond(content: "❌ Error obteniendo tag. Inténtalo de nuevo.", ephemeral: true)
    end
  end

  application_command(:tags) do |event|
    search = event.options["search"]

    begin
      guild_id = Rails.application.config.x.app.server_id

      # Get all tags for this guild
      tags = Tag.where(guild_id: guild_id)

      # Apply search filter if provided
      if search.present?
        tags = tags.where("LOWER(name) LIKE ?", "%#{search.downcase}%")
      end

      tags = tags.order(:name).limit(25) # Discord embed field limit

      if tags.empty?
        message = search.present? ?
          "❌ No se encontraron tags que coincidan con '#{search}'" :
          "❌ No hay tags creados en este servidor"
        event.respond(content: message, ephemeral: true)
        next
      end

      # Build response
      if search.present?
        title = "🔍 Tags que coinciden con '#{search}' (#{tags.count})"
      else
        total_count = Tag.where(guild_id: guild_id).count
        showing = tags.count
        title = showing == total_count ?
          "📋 Todos los tags (#{total_count})" :
          "📋 Tags (mostrando #{showing} de #{total_count})"
      end

      # Format tag list
      tag_list = tags.map do |tag|
        owner_name = tag.user.username || "Usuario desconocido"
        "• `#{tag.name}` (por #{owner_name})"
      end.join("\n")

      response_content = "#{title}\n\n#{tag_list}"

      # Discord has a 2000 character limit for message content
      if response_content.length > 1900
        response_content = response_content[0..1900] + "..."
      end

      event.respond(content: response_content)

    rescue => e
      Rails.logger.error "Error in tags list command: #{e.message}"
      event.respond(content: "❌ Error obteniendo lista de tags. Inténtalo de nuevo.", ephemeral: true)
    end
  end
end