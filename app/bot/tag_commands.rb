module TagCommands
  extend Discordrb::EventContainer
  extend CommandRegistry::Helpers

  define_subcommand(:tag, :get) do |event, params|
    tag = find_tag_for_display(event, params[:name])
    return unless tag

    if tag.image_url?
      event.respond(content: tag.content)
    else
      event.respond(content: "**#{tag.name}**: #{tag.content}")
    end
  end

  define_subcommand(:tag, :create) do |event, params|
    with_tag_service(event, :creando) do |service|
      tag = service.create_tag(name: params[:name], content: params[:content])
      "✅ Se ha creado la tag `#{tag.name}`"
    end
  end

  define_subcommand(:tag, :edit) do |event, params|
    with_tag_service(event, :actualizando) do |service|
      tag = find_tag_or_respond!(event, params[:name])
      return unless tag

      update_params = { content: params[:content] }
      update_params[:name] = params[:new_name] if params[:new_name].present?

      updated_tag = service.update_tag(tag, **update_params)
      "✅ Tag `#{updated_tag.name}` actualizada"
    end
  end

  define_subcommand(:tag, :delete) do |event, params|
    with_tag_service(event, :eliminando) do |service|
      tag = find_tag_or_respond!(event, params[:name])
      return unless tag

      service.destroy_tag(tag)
      "✅ Tag `#{params[:name]}` eliminada exitosamente"
    end
  end

  define_subcommand(:tag, :raw) do |event, params|
    tag = find_tag_for_display(event, params[:name])
    return unless tag

    raw_content = "```\n#{tag.content}\n```"
    event.respond(content: raw_content)
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

  # Unified service operation handler (like persist_tag in TagsService)
  # Handles defer, locale, user setup, service creation, and all error cases
  def with_tag_service(event, operation_name)
    event.defer

    response = I18n.with_locale(:es) do
      user = get_discord_user(event)
      service = TagsService.new(user)
      yield(service)
    end

    event.edit_response(content: response) if response
  rescue Tag::PermissionDenied => e
    event.edit_response(content: "❌ #{e.message}")
  rescue Tag::ValidationFailed => e
    event.edit_response(content: "❌ Error #{operation_name} tag: #{e.message}")
  rescue Tag::NotFound => e
    event.edit_response(content: "❌ #{e.message}")
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error "Database error #{operation_name} tag via bot: #{e.message}"
    event.edit_response(content: "❌ Error de base de datos, intenta de nuevo más tarde")
  rescue => e
    Rails.logger.error "Unexpected error #{operation_name} tag via bot: #{e.message}\n#{e.backtrace.join("\n")}"
    event.edit_response(content: "❌ Error inesperado #{operation_name} tag")
  end

  # For read operations - returns nil and responds if not found
  # Uses event.respond (not edit_response) since read ops aren't deferred
  def find_tag_for_display(event, name)
    tag = Tag.find_by_name(name)
    unless tag
      event.respond(content: "❌ No existe una tag con el nombre de `#{name}`", ephemeral: true)
      return nil
    end
    tag
  end

  # For write operations - returns nil and responds if not found
  # Uses event.edit_response since write ops are deferred (called after defer)
  def find_tag_or_respond!(event, name)
    tag = Tag.find_by_name(name)
    unless tag
      event.edit_response(content: "❌ No existe una tag con el nombre de `#{name}`")
      return nil
    end
    tag
  end

  def get_discord_user(event)
    User.find_or_create_from_discord(
      discord_uid: event.user.id.to_s,
      discord_user: event.user
    )
  end
end
