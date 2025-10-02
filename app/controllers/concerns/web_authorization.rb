module WebAuthorization
  extend ActiveSupport::Concern

  private

  def require_admin
    unless current_user&.discord_admin?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_moderator
    unless current_user&.discord_moderator?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_admin_or_moderator
    unless current_user&.discord_admin_or_mod?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_trusted
    unless current_user&.discord_trusted?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def admin_required!
    require_admin
  end

  def moderator_required!
    require_moderator
  end

  def admin_or_moderator_required!
    require_admin_or_moderator
  end

  def trusted_required!
    require_trusted
  end
end

