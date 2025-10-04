module AdminCommands
  extend Discordrb::EventContainer
  extend CommandRegistry::Helpers

  define_command(:time) do |event, params|
    event.defer(ephemeral: true)

    time_zone = Time.find_zone(params[:timezone]) || Time.zone
    formatted_time = time_zone.now.strftime("%Y-%m-%d %H:%M:%S %Z")

    event.edit_response(content: "Hora en #{time_zone.name}: #{formatted_time}")
  end

  define_autocomplete(:time, :timezone) do |event, value|
    timezones = ActiveSupport::TimeZone
      .all
      .select do |tz|
        tz.name.downcase.include?(value)
      end

    choices = timezones.first(20).map { |tz| [ tz.name, tz.name ] }.to_h

    event.respond(choices: choices)
  end
end
