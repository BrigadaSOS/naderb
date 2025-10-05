module WebAuthorization
  extend ActiveSupport::Concern

  def admin_required!
    unless current_user&.admin?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def admin_or_moderator_required!
    unless current_user&.admin_or_mod?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def trusted_required!
    unless current_user&.trusted_user?
      redirect_to root_path, alert: "Access denied."
    end
  end

  # Allow admins or in development mode for dev tools
  def admin_or_dev_required!
    unless current_user&.admin? || Rails.env.development?
      redirect_to root_path, alert: "Access denied."
    end
  end
end
