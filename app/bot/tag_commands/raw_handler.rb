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

    # TODO: Implement raw subcommand
    # def self.included(base)
    #   base.define_application_subcommand_handler(TagCommands.command_schema, :raw) do |event, params|
    #     event.defer(ephemeral: false)
    #
    #     tag = find_tag_or_respond!(event, params[:name])
    #     return unless tag
    #
    #     raw_content = "```\n#{tag.content}\n```"
    #     event.edit_response(content: raw_content)
    #   end
    # end
  end
end
