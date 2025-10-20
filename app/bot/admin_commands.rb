module AdminCommands
  extend Discordrb::EventContainer
  extend CommandHelpers

  def self.command_schema
    {
      name: "hora",
      description: "Muestra la hora",
      parameters: {
        timezone: { name: "zona_horaria", type: "string", required: false, description: "La zona horaria en la que mostrar la hora", autocomplete: true }
      }
    }
  end

  # Register time command
  define_command(command_schema) do |event|
    event.defer(ephemeral: true)

    params = extract_params_from_event(command_schema, event)
    time_zone = Time.find_zone(params[:timezone]) || Time.zone
    formatted_time = time_zone.now.strftime("%Y-%m-%d %H:%M:%S %Z")

    event.edit_response(content: "Hora en #{time_zone.name}: #{formatted_time}")
  end

  # TODO: Re-implement autocomplete for timezone
  # define_autocomplete(command_schema, :timezone) do |event, value|
  #   timezones = ActiveSupport::TimeZone
  #     .all
  #     .select do |tz|
  #       tz.name.downcase.include?(value)
  #     end
  #
  #   choices = timezones.first(20).map { |tz| [ tz.name, tz.name ] }.to_h
  #
  #   event.respond(choices: choices)
  # end
end
