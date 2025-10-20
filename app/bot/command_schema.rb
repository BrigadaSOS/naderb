class CommandSchema
  # Discover and collect all command schemas from command modules
  def self.all_commands
    commands = {}

    # Register TagCommands (main tag command + separate tags command)
    if defined?(TagCommands)
      commands[:tag] = TagCommands.command_schema
      commands[:tags] = TagCommands.tags_command_schema
    end

    # Register ProfileCommands
    if defined?(ProfileCommands)
      commands[:profile] = ProfileCommands.command_schema
    end

    # Register AdminCommands (time command)
    if defined?(AdminCommands)
      commands[:time] = AdminCommands.command_schema
    end

    commands
  end

  # Converts command definitions from hash to array format for views and API services
  def self.to_array
    all_commands.map do |key, definition|
      # Create a new hash to avoid modifying the original
      cmd = {
        name: definition[:name],
        description: definition[:description]
      }

      # Convert subcommands hash to array if present
      if definition[:subcommands].present?
        cmd[:subcommands] = definition[:subcommands].map do |sub_key, sub_def|
          converted_sub = {
            name: sub_def[:name],
            description: sub_def[:description]
          }

          # Convert parameters hash to array for subcommand
          if sub_def[:parameters].present?
            converted_sub[:parameters] = sub_def[:parameters].map do |param_key, param_def|
              param_def.dup
            end
          end

          converted_sub
        end
      end

      # Convert parameters hash to array if present
      if definition[:parameters].present?
        cmd[:parameters] = definition[:parameters].map do |param_key, param_def|
          param_def.dup
        end
      end

      cmd
    end
  end
end
