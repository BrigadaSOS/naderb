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

  private

  def execute_with_wrapper(event, command_name, &handler_method)
    user_info = event.user ? "#{event.user.username} (#{event.user.id})" : "unknown"
    message = "Command executed: /#{command_name} by #{user_info}"
    message += " with options: #{event.options.inspect}" if event.options&.any?
    log_info(message)

    handler_method.call(event)

    log_info("/#{command_name} completed")

  rescue => error
    log_error("Error in /#{command_name}: #{error.message}")
    log_error(error.backtrace.join("\n"))

    error_response = "❌ Error inesperado. Inténtalo de nuevo más tarde."
    begin
      event.edit_response(content: error_response)
    rescue
      event.respond(content: error_response, ephemeral: true)
    end
  end

  def log_info(message)
    Rails.logger.info(message)
    broadcast_log(message, :info)
  end

  def log_error(message)
    Rails.logger.error(message)
    broadcast_log(message, :error)
  end

  def broadcast_log(message, level)
    ActionCable.server.broadcast(
      "bot_updates",
      {
        type: "log",
        message: message.to_s,
        timestamp: Time.current.iso8601,
        level: level.to_s
      }
    )
  rescue => e
    Rails.logger.debug("Failed to broadcast log: #{e.message}")
  end
end
