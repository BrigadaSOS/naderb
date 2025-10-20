module TagCommands
  class Base
    class << self
      def with_tag_service(event)
        I18n.with_locale(:es) do
          user = get_discord_user(event)
          service = TagService.new(user)
          yield service
        end

      rescue TagExceptions::PermissionDenied => e
        event.edit_response(content: "❌ Error: #{e.message}")

      rescue TagExceptions::ValidationFailed => e
        event.edit_response(content: "❌ Error: #{e.message}")

      rescue TagExceptions::NotFound => e
        event.edit_response(content: "❌ Error: #{e.message}")

      rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.error "Database error tag via bot: #{e.message}"
        event.edit_response(content: "❌ Error de base de datos, intenta de nuevo más tarde")

      rescue => e
        Rails.logger.error "Unexpected error via bot: #{e.message}"
        event.edit_response(content: "❌ Error inesperado")
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
end
