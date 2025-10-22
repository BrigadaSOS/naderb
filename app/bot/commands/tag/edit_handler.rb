module TagCommands
  module EditHandler
    def self.command_schema
      {
        name: "edit",
        description: "Edita un tag existente",
        parameters: {
          name: { name: "name", type: "string", required: true, description: "Nombre del tag actual" },
          content: { name: "content", type: "string", required: true, description: "Nuevo contenido del tag" },
          new_name: { name: "new_name", type: "string", required: false, description: "Nuevo nombre del tag (opcional)" }
        }
      }
    end

    def self.included(base)
      base.define_subcommand(:tag, command_schema) do |event|
        event.defer(ephemeral: false)

        params = base.extract_subcommand_params(event, "tag")
        tag = base.find_tag_or_respond!(event, params.name)
        next unless tag

        base.with_tag_service(event) do |service|
          update_params = { content: params.content }
          update_params[:name] = params.new_name if params.new_name.present?

          updated_tag = service.update_tag(tag, **update_params)
          event.edit_response(content: "✅ Tag `#{updated_tag.name}` actualizada")
        end
      end
    end
  end
end
