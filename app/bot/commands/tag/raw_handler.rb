module TagCommands
  module RawHandler
    def self.command_schema
      {
        name: "raw",
        description: "Obtiene el contenido crudo de un tag",
        parameters: {
          name: { name: "name", type: "string", required: true, description: "Nombre del tag" }
        }
      }
    end

    def self.included(base)
      base.define_subcommand(:tag, command_schema) do |event|
        event.defer(ephemeral: false)

        params = base.extract_subcommand_params(event, "tag")
        tag = base.find_tag_or_respond!(event, params.name)
        next unless tag

        raw_content = "```\n#{tag.content}\n```"
        event.edit_response(content: raw_content)
      end
    end
  end
end
