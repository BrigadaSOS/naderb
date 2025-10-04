  module TagCommands
    extend Discordrb::EventContainer
    extend CommandRegistry::Helpers

    define_subcommand(:tag, :get) do |event, params|
      tag = Tag.find_by_name(params[:name])

      if tag
        if tag.image_url?
          event.respond(content: tag.content)
        else
          event.respond(content: "**#{tag.name}**: #{tag.content}")
        end
      else
        event.respond(content: "❌ No existe una tag con el nombre de `#{params[:name]}`", ephemeral: true)
      end
    end

    define_subcommand(:tag, :create) do |event, params|
      event.defer()

      user = get_discord_user(event)

      tags_service = TagsService.new(user)
      result = tags_service.create_tag(name: params[:name], content: params[:content])

      if result[:success]
        event.edit_response(content: "✅ Se ha creado la tag `#{result[:tag].name}`")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error creando tag: #{errors}")
      end
    end

    define_subcommand(:tag, :edit) do |event, params|
      event.defer()

      user = get_discord_user(event)

      tag = Tag.find_by_name(params[:name])
      # Update tag using TagsService
      update_params = { content: params[:content] }
      update_params[:name] = params[:new_name] if params[:new_name].present?

      tags_service = TagsService.new(user)
      result = tags_service.update_tag(tag, update_params)

      if result[:success]
        updated_name = result[:tag].name
        event.edit_response(content: "✅ Tag `#{updated_name}` actualizada")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error actualizando tag: #{errors}")
      end
    end

    define_subcommand(:tag, :delete) do |event, params|
      event.defer()

      tag = Tag.find_by_name(params[:name])
      if tag.nil?
        event.edit_response(content: "❌ No existe una tag con el nombre de `#{params[:name]}`")
        next
      end

      unless tag.is_editable_by(user)
        event.edit_response(content: "❌ Solo puedes eliminar tus propias tags")
        next
      end

      # Delete tag using TagsService
      tags_service = TagsService.new(user)
      result = tags_service.destroy_tag(tag)

      if result[:success]
        event.edit_response(content: "✅ Tag `#{params[:name]}` eliminada exitosamente")
      else
        errors = result[:tag].errors.full_messages.join(", ")
        event.edit_response(content: "❌ Error eliminando tag: #{errors}")
      end
    end

    define_subcommand(:tag, :raw) do |event, params|
      tag = Tag.find_by_name(params[:name])

      if tag
        raw_content = "```\n#{tag.content}\n```"
        event.respond(content: raw_content)
      else
        event.respond(content: "❌ Tag `#{params[:name]}` no encontrado", ephemeral: true)
      end
    end

    define_command(:tags) do |event, params|
      guild_id = Setting.discord_server_id

      # Get all tags for this guild
      tags = Tag.where(guild_id: guild_id)

      # Apply search filter if provided
      if params[:search].present?
        tags = tags.where("LOWER(name) LIKE ?", "%#{params[:search].downcase}%")
      end

      tags = tags.order(:name)

      if tags.empty?
        message = params[:search].present? ?
          "❌ No se encontraron tags que coincidan con '#{params[:search]}'" :
          "❌ No hay tags en este servidor"
        event.respond(content: message, ephemeral: true)
        next
      end

      # Build response
      if params[:search].present?
        title = "🔍 Tags que coinciden con '#{params[:search]}' (#{tags.count})"
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

    private

    def with_discord_user(event)
      user = User.find_or_create_from_discord(
        discord_uid: event.user.id.to_s,
        discord_user: event.user
      )

      if user
        yield(user)
      else
        event.edit_response(content: "❌ Error inesperado")
      end
    end

    def with_editable_tag(event, tag_name)
      tag = Tag.find_by_name(tag_name)

      if tag.nil?
        event.edit_response(content: "❌ No existe una tag con el nombre de `#{params[:name]}`")
        return
      end

      unless tag.is_editable_by(user)
        event.edit_response(content: "❌ Solo puedes editar tus propias tags")
        return
      end

      if tag
        yield(tag)
      else
        event.edit_response(content: "❌ No existe una tag con el nombre de `#{tag_name}`")
      end
    end
  end
