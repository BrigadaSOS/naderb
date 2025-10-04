class CommandRegistry
  COMMAND_DEFINITIONS = {
    time: {
      name: "hora",
      description: "Muestra la hora",
      parameters: {
        timezone: { name: "zona_horaria", type: "string", required: false, description: "La zona horaria en la que mostrar la hora", autocomplete: true }
      }
    },
    profile: {
      name: "perfil",
      description: "Modifica un perfil",
      subcommands: {
        info: {
          name: "info",
          description: "Muestra información del perfil de un usuario",
          parameters: {
            user: { name: "usuario", type: "user", required: true, description: "Usuario a mostrar" }
          }
        },
        birthday: {
          name: "cumple",
          description: "Configura tu fecha de cumple",
          parameters: {
            day: { name: "dia", type: "number", required: true, description: "Día del mes (1-31)" },
            month: { name: "mes", type: "string", required: true, description: "Mes del año (1-12)" }
          }
        }
      }
    },
    tag: {
      name: "tag",
      description: "Gestiona tags del servidor",
      subcommands: {
        create: {
          name: "create",
          description: "Crea un nuevo tag",
          parameters: {
            name: { name: "name", type: "string", required: true, description: "Nombre del tag" },
            content: { name: "content", type: "string", required: true, description: "Contenido del tag" }
          }
        },
        get: {
          name: "get",
          description: "Obtiene un tag existente",
          parameters: {
            name: { name: "name", type: "string", required: true, description: "Nombre del tag" }
          }
        },
        edit: {
          name: "edit",
          description: "Edita un tag existente",
          parameters: {
            name: { name: "name", type: "string", required: true, description: "Nombre del tag actual" },
            content: { name: "content", type: "string", required: true, description: "Nuevo contenido del tag" },
            new_name: { name: "new_name", type: "string", required: false, description: "Nuevo nombre del tag (opcional)" }
          }
        },
        delete: {
          name: "delete",
          description: "Elimina un tag",
          parameters: {
            name: { name: "name", type: "string", required: true, description: "Nombre del tag a eliminar" }
          }
        },
        raw: {
          name: "raw",
          description: "Obtiene el contenido crudo de un tag",
          parameters: {
            name: { name: "name", type: "string", required: true, description: "Nombre del tag" }
          }
        }
      }
    },
    tags: {
      name: "tags",
      description: "Lista todos los tags del servidor",
      parameters: {
        search: { name: "search", type: "string", required: false, description: "Buscar tags por nombre (opcional)" }
      }
    }
  }.freeze

  class CommandAccessor
    def initialize(definition)
      @definition = definition
    end

    def name
      @definition[:name].to_sym
    end

    def description
      @definition[:description]
    end

    def param(key)
      ParameterAccessor.new(@definition[:parameters][key])
    end

    def subcommand(key)
      SubcommandAccessor.new(@definition[:subcommands][key])
    end
  end

  class ParameterAccessor
    def initialize(definition)
      @definition = definition
    end

    def name
      @definition[:name].to_sym
    end

    def type
      @definition[:type]
    end

    def required?
      @definition[:required]
    end

    def description
      @definition[:description]
    end
  end

  class SubcommandAccessor
    def initialize(definition)
      @definition = definition
    end

    def name
      @definition[:name].to_sym
    end

    def description
      @definition[:description]
    end

    def param(key)
      ParameterAccessor.new(@definition[:parameters][key])
    end
  end

  # Metaprogramming: automatically create accessor methods for all commands
  COMMAND_DEFINITIONS.each do |key, definition|
    instance_var = "@#{key}"

    define_singleton_method(key) do
      instance_variable_get(instance_var) ||
        instance_variable_set(instance_var, CommandAccessor.new(definition))
    end
  end

  # Helper method for legacy code that expects array format
  def self.command_definitions
    COMMAND_DEFINITIONS.map do |key, definition|
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

  def register_all_commands(guild_only: false)
    server_id = guild_only ? Setting.discord_server_id : nil

    COMMAND_DEFINITIONS.each do |_key, definition|
      register_application_command(definition[:name].to_sym, definition[:description], server_id: server_id) do |command|
        build_command_structure(command, definition)
      end
    end
  end

  private

  def build_command_structure(command, definition)
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

  def add_parameters(target, parameters)
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

  module Helpers
    def define_command(command_key, &block)
      command_def = CommandRegistry::COMMAND_DEFINITIONS[command_key]

      application_command(command_def[:name].to_sym) do |event|
        params = {}
        command_def[:parameters]&.each do |key, param|
          params[key] = event.options[param[:name]]
        end

        block.call(event, params)
      end
    end

    def define_subcommand(command_key, subcommand_key, &block)
      command_def = CommandRegistry::COMMAND_DEFINITIONS[command_key]
      subcommand_def = command_def[:subcommands][subcommand_key]

      application_command(command_def[:name].to_sym).subcommand(subcommand_def[:name].to_sym) do |event|
        params = {}
        subcommand_def[:parameters]&.each do |key, param|
          params[key] = event.options[param[:name]]
        end

        block.call(event, params)
      end
    end

    def define_autocomplete(command_key, param_key, &block)
      command_def = CommandRegistry::COMMAND_DEFINITIONS[command_key]
      param_def = command_def[:parameters][param_key]

      autocomplete(param_def[:name].to_sym) do |event|
        value = event.options[param_def[:name]]
        block.call(event, value)
      end
    end
  end
end
