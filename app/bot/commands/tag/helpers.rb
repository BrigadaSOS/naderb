module TagCommands
  module Helpers
    include ErrorHandler

    def with_tag_service(event)
      result = handle_tag_errors do
        I18n.with_locale(:es) do
          user = get_discord_user(event)
          service = Tags::TagService.new(user)
          yield service
        end
      end

      unless result.success?
        error_message = case result.error[:type]
        when :permission_denied, :validation_failed, :not_found
          "❌ Error: #{result.error[:message]}"
        when :database_error
          "❌ Error de base de datos, intenta de nuevo más tarde"
        else
          "❌ Error inesperado"
        end

        event.edit_response(content: error_message)
      end

      result.data
    end

    def find_tag_or_respond!(event, name)
      if name.blank?
        Rails.logger.warn "Tag lookup attempted with blank name"
        event.edit_response(content: "❌ Debes especificar el nombre de una tag")
        return nil
      end

      Rails.logger.info "Finding tag: #{name}"
      tag = Tag.find_by_name(name)

      if tag
        Rails.logger.info "Tag found: #{tag.name} (ID: #{tag.id})"
      else
        Rails.logger.info "Tag not found: #{name}"
        event.edit_response(content: "❌ No existe una tag con el nombre de `#{name}`")
      end

      tag
    end

    def get_discord_user(event)
      User.find_or_create_from_discord(
        discord_uid: event.user.id.to_s,
        discord_user: event.user
      )
    end
  end
end
