module TagCommands
  module CreateHandler
    extend CommandHelpers
    def self.command_schema
      {
        name: "create",
        description: "Crea un nuevo tag",
        parameters: {
          name: { name: "name", type: "string", required: true, description: "Nombre del tag" },
          content: { name: "content", type: "string", required: false, description: "Contenido del tag (texto o URL)" },
          attachment: { name: "attachment", type: "attachment", required: false, description: "Imagen del tag" }
        }
      }
    end

    def self.included(base)
      base.define_subcommand(:tag, command_schema) do |event|
        event.defer(ephemeral: false)

        params = base.extract_subcommand_params(event, "tag")

        base.with_tag_service(event) do |service|
          attachment = params.attachment
          content = params.content

          if content.blank? && attachment.nil?
            event.edit_response(content: "❌ Debes proporcionar contenido o una imagen")
            next
          end

          if attachment.present?
            discord_cdn_url = event.resolved.attachments[params.attachment.to_i].url
          end

          tag = service.create_tag(name: params.name, content: content, discord_cdn_url: discord_cdn_url)

          event.edit_response(content: "✅ Se ha creado la tag `#{tag.name}`")
        end
      end
    end
  end
end
