module Users
  module RoleChecker
    extend ActiveSupport::Concern

    attr_reader :impersonated_roles

    def admin_or_mod?
      admin? || moderator?
    end

    def admin?
      has_any_discord_role?(Setting.discord_admin_roles)
    end

    def moderator?
      has_any_discord_role?(Setting.discord_moderator_roles)
    end

    def trusted_user?
      has_any_discord_role?(Setting.trusted_user_roles)
    end

    def has_discord_role?(role_id)
      discord_roles.any? { |role| role["id"].to_s == role_id.to_s }
    end

    def has_any_discord_role?(role_ids)
      role_ids.any? { |role_id| has_discord_role?(role_id) }
    end

    def impersonated_roles=(roles)
      unless Rails.env.development? || Rails.env.test?
        Rails.logger.warn "Attempted to set impersonated_roles in #{Rails.env} environment - ignoring"
        return
      end
      @impersonated_roles = roles
    end

    private

    # Returns user's Discord roles, using impersonated roles in development if set
    def discord_roles
      if Rails.env.development? && @impersonated_roles.present?
        return @impersonated_roles.map { |role_id| { "id" => role_id } }
      end

      guild_id = Setting.discord_server_id
      Rails.cache.fetch("#{guild_id}_#{discord_uid}_discord_roles", expires_in: 1.days) do
        fetch_discord_roles
      end
    end

    def fetch_discord_roles
      begin
        discord_api = Discord::Api::UserService.new(self)
        discord_api.fetch_member_info()
      rescue => e
        Rails.logger.error "Failed to fetch Discord roles for UID #{uid}: #{e.message}"
          []
      end
    end
  end
end
