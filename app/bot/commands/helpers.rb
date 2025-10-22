module CommandHelpers
  def define_command(command_definition, &handler_method)
    command_name = command_definition.fetch(:name).to_sym

    application_command(command_name) do |event|
      execute_with_wrapper(event, command_name, &handler_method)
    end
  end

  def define_subcommand(command_name, subcommand_definition, &handler_method)
    subcommand_name = subcommand_definition.fetch(:name).to_sym

    application_command(command_name).subcommand(subcommand_name) do |event|
      execute_with_wrapper(event, subcommand_name, &handler_method)
    end
  end

  def extract_params_from_event(command_definition, event)
    (command_definition[:parameters] || {}).transform_values do |param|
      event.options[param[:name]]
    end
  end

  # Extract parameters from a subcommand event
  # Returns an OpenStruct with the subcommand name and all parameter values
  # @param event [Discordrb::Events::ApplicationCommandEvent] The Discord event
  # @param command_name [String] The parent command name (e.g., "tag")
  # @return [OpenStruct] Object with subcommand name and parameters as attributes
  #
  # Example:
  #   params = extract_subcommand_params(event, "tag")
  #   params.subcommand #=> "create"
  #   params.name       #=> "my_tag"
  #   params.content    #=> "Hello world"
  def extract_subcommand_params(event, command_name)
    subcommand_options = event.options[command_name]&.dig("options")&.first || {}
    subcommand_name = subcommand_options["name"]

    options_hash = (subcommand_options.dig("options") || []).each_with_object({}) do |opt, hash|
      hash[opt["name"].to_sym] = opt["value"]
    end

    OpenStruct.new(
      subcommand: subcommand_name,
      **options_hash
    )
  end

  # Extract parameters from a direct command event (no subcommands)
  # Returns an OpenStruct with all parameter values as attributes
  # @param event [Discordrb::Events::ApplicationCommandEvent] The Discord event
  # @return [OpenStruct] Object with parameters as attributes
  #
  # Example:
  #   params = extract_command_params(event)
  #   params.search #=> "query"
  def extract_command_params(event)
    options_hash = (event.options || []).each_with_object({}) do |opt, hash|
      hash[opt["name"].to_sym] = opt["value"]
    end

    OpenStruct.new(**options_hash)
  end

  private

  def execute_with_wrapper(event, command_name, &handler_method)
    user_info = event.user ? "#{event.user.username} (#{event.user.id})" : "unknown"
    message = "Command executed: /#{command_name} by #{user_info}"
    message += " with options: #{event.options.inspect}" if event.options&.any?
    Discord::LogBroadcaster.info(message)

    handler_method.call(event)

    Discord::LogBroadcaster.info("/#{command_name} completed")

  rescue => error
    Discord::LogBroadcaster.error("Error in /#{command_name}: #{error.message}", exception: error)

    error_response = "❌ Error inesperado. Inténtalo de nuevo más tarde."
    begin
      event.edit_response(content: error_response)
    rescue
      event.respond(content: error_response, ephemeral: true)
    end
  end
end
