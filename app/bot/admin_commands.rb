module AdminCommands
  extend Discordrb::EventContainer

  application_command(:hora) do |event|
    event.defer(ephemeral: true)

    timezone = event.options["zona_horaria"]

    time_zone = Time.find_zone(timezone) || Time.zone

    current_time = time_zone.now
    formatted_time = current_time.strftime("%Y-%m-%d %H:%M:%S %Z")
    event.edit_response(content: "Hora en #{time_zone.name}: #{formatted_time}")
  end

  autocomplete(:zona_horaria) do |event|
    option = event.options["zona_horaria"]

    timezones = ActiveSupport::TimeZone
      .all
      .select do |tz|
        tz.name.downcase.include?(option)
      end

    choices = timezones.first(20).map { |tz| [ tz.name, tz.name ] }.to_h

    event.respond(choices: choices)
  end
end
