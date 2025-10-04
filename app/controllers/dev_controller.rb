# Development-only controller for testing role and user impersonation
class DevController < ApplicationController
  before_action :ensure_development_environment
  skip_before_action :verify_authenticity_token, only: [:impersonate]

  def impersonate
    role_ids = params[:role_ids]&.reject(&:blank?) || []
    user_id = params[:user_id]

    Rails.logger.debug "DevController#impersonate called with user_id: #{user_id.inspect}, role_ids: #{role_ids.inspect}"

    session[:impersonated_roles] = role_ids

    if user_id.present? && user_id != ""
      user = User.find_by(id: user_id)
      if user
        impersonate_user(user)
        Rails.logger.debug "🎭 Impersonating user: #{user.name} (ID: #{user.id})"
        message = "Impersonating #{user.name} with #{role_ids.size} role(s)"
      else
        stop_impersonating_user
        message = "User not found, impersonating #{role_ids.size} role(s)"
      end
    else
      stop_impersonating_user
      Rails.logger.debug "Cleared user impersonation"
      message = "Impersonating #{role_ids.size} role(s)"
    end

    redirect_back(fallback_location: root_path, notice: message)
  end

  def clear_impersonation
    session.delete(:impersonated_roles)
    stop_impersonating_user
    redirect_back(fallback_location: root_path, notice: "Using real user and Discord roles")
  end

  private

  def ensure_development_environment
    raise ActionController::RoutingError, "Not Found" unless Rails.env.development?
  end
end
