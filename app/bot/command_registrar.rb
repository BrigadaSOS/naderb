class CommandRegistrar
  # Class method to register commands on a bot instance
  def self.register_all_commands(bot, guild_only: false)
    server_id = guild_only ? Setting.discord_server_id : nil

    CommandSchema.all_commands.each do |_key, definition|
      bot.register_application_command(definition[:name].to_sym, definition[:description], server_id: server_id) do |command|
        build_command_structure(command, definition)
      end
    end
  end

  def self.build_command_structure(command, definition)
    if definition[:subcommands].present?
      # Group all subcommands
      definition[:subcommands].each do |_key, subcommand|
        command.subcommand(subcommand[:name].to_sym, subcommand[:description]) do |sub|
          add_parameters(sub, subcommand[:parameters]) if subcommand[:parameters].present?
        end
      end
    elsif definition[:parameters].present?
      # Direct parameters
      add_parameters(command, definition[:parameters])
    end
  end

  def self.add_parameters(target, parameters)
    parameters.each do |_key, param|
      param_name = param[:name].to_sym
      case param[:type].to_s.downcase
      when "string"
        target.string(param_name, param[:description], required: param[:required] || false, autocomplete: param[:autocomplete] || false)
      when "number", "integer"
        target.integer(param_name, param[:description], required: param[:required] || false)
      when "boolean"
        target.boolean(param_name, param[:description], required: param[:required] || false)
      when "user"
        target.user(param_name, param[:description], required: param[:required] || false)
      when "channel"
        target.channel(param_name, param[:description], required: param[:required] || false)
      when "role"
        target.role(param_name, param[:description], required: param[:required] || false)
      when "mentionable"
        target.mentionable(param_name, param[:description], required: param[:required] || false)
      else
        target.string(param_name, param[:description], required: param[:required] || false)
      end
    end
  end
end
