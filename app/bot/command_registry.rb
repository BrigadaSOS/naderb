class CommandRegistry
  def self.command_definitions
    [
      {
        name: "hora",
        description: "Muestra la hora",
        parameters: [
          { name: "zona_horaria", type: "string", required: false, description: "La zona horaria en la que mostrar la hora", autocomplete: true }
        ]
      },
      {
        name: "perfil",
        description: "Modifica un perfil",
        subcommands: [
          {
            name: "info",
            description: "Muestra información del perfil de un usuario",
            parameters: [
              { name: "usuario", type: "user", required: true, description: "Usuario a mostrar" }
            ]
          },
          {
            name: "cumple",
            description: "Configura tu fecha de cumple",
            parameters: [
              { name: "dia", type: "number", required: true, description: "Día del mes (1-31)" },
              { name: "mes", type: "string", required: true, description: "Mes del año (1-12)" }
            ]
          }
        ]
      },
      {
        name: "tag",
        description: "Gestiona tags del servidor",
        subcommands: [
          {
            name: "create",
            description: "Crea un nuevo tag",
            parameters: [
              { name: "name", type: "string", required: true, description: "Nombre del tag" },
              { name: "content", type: "string", required: true, description: "Contenido del tag" }
            ]
          },
          {
            name: "get",
            description: "Obtiene un tag existente",
            parameters: [
              { name: "name", type: "string", required: true, description: "Nombre del tag" }
            ]
          },
          {
            name: "edit",
            description: "Edita un tag existente",
            parameters: [
              { name: "name", type: "string", required: true, description: "Nombre del tag actual" },
              { name: "content", type: "string", required: true, description: "Nuevo contenido del tag" },
              { name: "new_name", type: "string", required: false, description: "Nuevo nombre del tag (opcional)" }
            ]
          },
          {
            name: "delete",
            description: "Elimina un tag",
            parameters: [
              { name: "name", type: "string", required: true, description: "Nombre del tag a eliminar" }
            ]
          },
          {
            name: "raw",
            description: "Obtiene el contenido crudo de un tag",
            parameters: [
              { name: "name", type: "string", required: true, description: "Nombre del tag" }
            ]
          }
        ]
      },
      {
        name: "tags",
        description: "Lista todos los tags del servidor",
        parameters: [
          { name: "search", type: "string", required: false, description: "Buscar tags por nombre (opcional)" }
        ]
      }
    ]
  end
end
