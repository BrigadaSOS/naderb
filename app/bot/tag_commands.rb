module TagCommands
  extend Discordrb::EventContainer
  extend CommandRegistry::Helpers

  define_subcommand(:tag, :get) do |event, params|
    event.defer(ephemeral: false)

    tag = self.find_tag_or_respond!(event, params[:name])
    return unless tag

    if tag.image_url?
      event.edit_response(content: tag.content)
    else
      event.edit_response(content: "**#{tag.name}**: #{tag.content}")
    end
  end

  define_subcommand(:tag, :create) do |event, params|
    event.defer(ephemeral: false)

    self.with_tag_service(event) do |service|
      tag = service.create_tag(name: params[:name], content: params[:content])

      event.edit_response(content: "✅ Se ha creado la tag `#{tag.name}`")
    end
  end

  define_subcommand(:tag, :edit) do |event, params|
    event.defer(ephemeral: false)

    self.with_tag_service(event) do |service|
      tag = self.find_tag_or_respond!(event, params[:name])
      return unless tag

      update_params = { content: params[:content] }
      update_params[:name] = params[:new_name] if params[:new_name].present?

      updated_tag = service.update_tag(tag, **update_params)
      event.edit_response(content: "✅ Tag `#{updated_tag.name}` actualizada")
    end
  end

  define_subcommand(:tag, :delete) do |event, params|
    event.defer(ephemeral: false)

    self.with_tag_service(event) do |service|
      tag = self.find_tag_or_respond!(event, params[:name])
      return unless tag

      service.destroy_tag(tag)
      event.edit_response(content: "✅ Tag `#{params[:name]}` eliminada exitosamente")
    end
  end

  define_subcommand(:tag, :raw) do |event, params|
    event.defer(ephemeral: false)

    tag = self.find_tag_or_respond!(event, params[:name])
    return unless tag

    raw_content = "```\n#{tag.content}\n```"
    event.edit_response(content: raw_content)
  end

  define_command(:tags) do |event, params|
    event.defer(ephemeral: false)

    tags = Tag.where(guild_id: Setting.discord_server_id)

    if params[:search].present?
      tags = tags.where("LOWER(name) LIKE ?", "%#{params[:search].downcase}%")
    end

    tags = tags.order(:name)

    if tags.empty?
      message = params[:search].present? ?
        "❌ No se encontraron tags que coincidan con '#{params[:search]}'" :
        "❌ No hay tags en este servidor"
      event.edit_response(content: message)
      next
    end

    if params[:search].present?
      title = "🔍 Tags que coinciden con '#{params[:search]}' (#{tags.count})"
    else
      title = "📋 Todos los tags (#{tags.count})"
    end

    # Format tag list
    tag_list = tags.map do |tag|
      owner_name = tag.user.display_name || tag.user.username || "???"
      "• `#{tag.name}` (por #{owner_name})"
    end.join("\n")

    response_content = "#{title}\n\n#{tag_list}"

    # Discord has a 2000 character limit for message content
    if response_content.length > 1900
      response_content = response_content[0..1900] + "..."
    end

    event.edit_response(content: response_content)
  end

  def self.with_tag_service(event)
    begin
      I18n.with_locale(:es) do
        user = self.get_discord_user(event)
        service = TagService.new(user)
        yield service
      end

    rescue Tag::PermissionDenied => e
      event.edit_response(content: "❌ Error: #{e.message}")

    rescue Tag::ValidationFailed => e
      event.edit_response(content: "❌ Error: #{e.message}")

    rescue Tag::NotFound => e
      event.edit_response(content: "❌ Error: #{e.message}")

    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "Database error tag via bot: #{e.message}"
        event.edit_response(content: "❌ Error de base de datos, intenta de nuevo más tarde")

    rescue => e
      Rails.logger.error "Unexpected error via bot: #{e.message}}"
        event.edit_response(content: "❌ Error inesperado")
    end
  end

  def self.find_tag_or_respond!(event, name)
    tag = Tag.find_by_name(name)

    event.edit_response(content: "❌ No existe una tag con el nombre de `#{name}`") unless tag
    tag
  end

  def self.get_discord_user(event)
    User.find_or_create_from_discord(
      discord_uid: event.user.id.to_s,
      discord_user: event.user
    )
  end
end
