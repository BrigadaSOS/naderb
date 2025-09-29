module WebAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :ensure_web_enabled
  end

  private

  def ensure_web_enabled
    unless current_user&.web_enabled?
      redirect_to root_path, alert: 'Access denied. Web access is required.'
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied. Admin role required.'
    end
  end

  def admin_required!
    require_admin
  end
end