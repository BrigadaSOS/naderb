  module TagCommands
    extend Discordrb::EventContainer

    application_command(:tag).subcommand(:create) do |event|
      event.defer(ephemeral: true)

      name = event.options["name"]
      content = event.options["content"]
      discord_uid = event.user.id.to_s

      # Find or create Discord-only user
      user = User.find_or_create_from_discord(
        discord_uid: discord_uid,
        username: event.user.username
      )

      tags_service = TagsService.new(user)
      result = tags_service.create_tag(name: name, content: content)

      if result[:success]
        event.edit_response(content: "✅ Se ha creado la tag `#{result[:tag].name}`")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error creando tag: #{errors}")
      end
    end

    application_command(:tag).subcommand(:get) do |event|
      name = event.options["name"]

      tag = Tag.find_by_name(name)

      if tag
        if tag.image_url?
          event.respond(content: tag.content)
        else
          event.respond(content: "**#{tag.name}**: #{tag.content}")
        end
      else
        event.respond(content: "❌ No existe una tag con el nombre de `#{name}`", ephemeral: true)
      end
    end

    application_command(:tag).subcommand(:edit) do |event|
      event.defer(ephemeral: true)

      name = event.options["name"]
      content = event.options["content"]
      new_name = event.options["new_name"]
      discord_uid = event.user.id.to_s

      user = User.find_or_create_from_discord(
        discord_uid: discord_uid,
        username: event.user.username
      )

      tag = Tag.find_by_name(name)
      if tag.nil?
        event.edit_response(content: "❌ No existe una tag con el nombre de `#{name}`")
        next
      end

      # Check if user owns the tag or is admin/mod
      unless tag.user == user || user.discord_admin_or_mod?
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
        event.edit_response(content: "✅ Tag `#{updated_name}` actualizada")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error actualizando tag: #{errors}")
      end
    end

    application_command(:tag).subcommand(:delete) do |event|
      event.defer(ephemeral: true)

      name = event.options["name"]
      discord_uid = event.user.id.to_s

      user = User.find_or_create_from_discord(
        discord_uid: discord_uid,
        username: event.user.username
      )

      tag = Tag.find_by_name(name)
      if tag.nil?
        event.edit_response(content: "❌ No existe una tag llamada `#{name}`")
        next
      end

      # Check if user owns the tag or is admin/mod
      unless tag.user == user || user.discord_admin_or_mod?
        event.edit_response(content: "❌ Solo puedes eliminar tus propias tags")
        next
      end

      # Delete tag using TagsService
      tags_service = TagsService.new(user)
      result = tags_service.destroy_tag(tag)

      if result[:success]
        event.edit_response(content: "✅ Tag `#{name}` eliminada exitosamente")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error eliminando tag: #{errors}")
      end
    end

    application_command(:tag).subcommand(:raw) do |event|
      name = event.options["name"]

      tag = Tag.find_by_name(name)

      if tag
        raw_content = "```\n#{tag.content}\n```"
        event.respond(content: raw_content)
      else
        event.respond(content: "❌ Tag `#{name}` no encontrado", ephemeral: true)
      end
    end

    application_command(:tags) do |event|
      search = event.options["search"]

      guild_id = Setting.discord_server_id

      # Get all tags for this guild
      tags = Tag.where(guild_id: guild_id)

      # Apply search filter if provided
      if search.present?
        tags = tags.where("LOWER(name) LIKE ?", "%#{search.downcase}%")
      end

      tags = tags.order(:name)

      if tags.empty?
        message = search.present? ?
          "❌ No se encontraron tags que coincidan con '#{search}'" :
          "❌ No hay tags en este servidor"
        event.respond(content: message, ephemeral: true)
        next
      end

      # Build response
      if search.present?
        title = "🔍 Tags que coinciden con '#{search}' (#{tags.count})"
      else
        title = "📋 Todos los tags (#{tags.count})"
      end

      # Format tag list
      tag_list = tags.map do |tag|
        owner_name = tag.user.username || "???"
        "• `#{tag.name}` (por #{owner_name})"
      end.join("\n")

      response_content = "#{title}\n\n#{tag_list}"

      # Discord has a 2000 character limit for message content
      if response_content.length > 1900
        response_content = response_content[0..1900] + "..."
      end

      event.respond(content: response_content)
    end
  end
