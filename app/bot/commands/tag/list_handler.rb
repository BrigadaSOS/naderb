module TagCommands
  module ListHandler
    def self.command_schema
      {
        name: "tags",
        description: "Lista todos los tags del servidor",
        parameters: {
          search: { name: "search", type: "string", required: false, description: "Buscar tags por nombre (opcional)" }
        }
      }
    end

    def self.included(base)
      base.define_command(command_schema) do |event|
        event.defer(ephemeral: false)

        params = base.extract_command_params(event)
        tags = Tag.where(guild_id: Setting.discord_server_id)

        if params.search.present?
          tags = tags.where("LOWER(name) LIKE ?", "%#{params.search.downcase}%")
        end

        tags = tags.order(:name)

        if tags.empty?
          message = params.search.present? ?
            "❌ No se encontraron tags que coincidan con '#{params.search}'" :
            "❌ No hay tags en este servidor"
          event.edit_response(content: message)
          next
        end

        if params.search.present?
          title = "🔍 Tags que coinciden con '#{params.search}' (#{tags.count})"
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
    end
  end
end
