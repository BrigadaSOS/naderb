module TagCommands
  module DeleteHandler
    def self.command_schema
      {
        name: "delete",
        description: "Elimina un tag",
        parameters: {
          name: { name: "name", type: "string", required: true, description: "Nombre del tag a eliminar" }
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
          service.destroy_tag(tag)
          event.edit_response(content: "✅ Tag `#{tag.name}` eliminada exitosamente")
        end
      end
    end
  end
end
