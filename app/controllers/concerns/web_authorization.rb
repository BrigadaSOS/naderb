module WebAuthorization
  extend ActiveSupport::Concern

  def admin_required!
    unless current_user&.admin?(impersonated_roles: impersonated_roles)
      redirect_to root_path, alert: "Access denied."
    end
  end

  def admin_or_moderator_required!
    unless current_user&.admin_or_mod?(impersonated_roles: impersonated_roles)
      redirect_to root_path, alert: "Access denied."
    end
  end

  def trusted_required!
    unless current_user&.trusted_user?(impersonated_roles: impersonated_roles)
      redirect_to root_path, alert: "Access denied."
    end
  end

  # Allow admins or in development mode for dev tools
  def admin_or_dev_required!
    unless current_user&.admin?(impersonated_roles: impersonated_roles) || Rails.env.development?
      redirect_to root_path, alert: "Access denied."
    end
  end

  private

  def impersonated_roles
    Rails.env.development? ? session[:impersonated_roles] : nil
  end
end
