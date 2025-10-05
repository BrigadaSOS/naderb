class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Toastable

  impersonates :user

  around_action :switch_locale
  before_action :set_impersonated_roles

  private

  def switch_locale(&action)
    locale = I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def set_impersonated_roles
    return unless current_user && Rails.env.development?

    current_user.impersonated_roles = session[:impersonated_roles]
  end
end
