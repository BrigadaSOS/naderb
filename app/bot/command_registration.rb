module CommandRegistration
  def register_all_commands(guild_only: false)
    server_id = guild_only ? Setting.discord_server_id : nil

    CommandRegistry.command_definitions.each do |cmd|
      register_application_command(cmd[:name].to_sym, cmd[:description], server_id: server_id) do |command|
        build_command_structure(command, cmd)
      end
    end
  end

  private

  def build_command_structure(command, definition)
    if definition[:subcommands].present?
      # Group all subcommands
      definition[:subcommands].each do |sub|
        command.subcommand(sub[:name].to_sym, sub[:description]) do |subcommand|
          add_parameters(subcommand, sub[:parameters]) if sub[:parameters].present?
        end
      end
    elsif definition[:parameters].present?
      # Direct parameters
      add_parameters(command, definition[:parameters])
    end
  end

  def add_parameters(target, parameters)
    parameters.each do |param|
      case param[:type].to_s.downcase
      when "string"
        target.string(param[:name], param[:description], required: param[:required] || false, autocomplete: param[:autocomplete] || false)
      when "number", "integer"
        target.integer(param[:name], param[:description], required: param[:required] || false)
      when "boolean"
        target.boolean(param[:name], param[:description], required: param[:required] || false)
      when "user"
        target.user(param[:name], param[:description], required: param[:required] || false)
      when "channel"
        target.channel(param[:name], param[:description], required: param[:required] || false)
      when "role"
        target.role(param[:name], param[:description], required: param[:required] || false)
      when "mentionable"
        target.mentionable(param[:name], param[:description], required: param[:required] || false)
      else
        target.string(param[:name], param[:description], required: param[:required] || false)
      end
    end
  end
end
