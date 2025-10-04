class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Toastable

  impersonates :user

  around_action :switch_locale
  helper_method :impersonated_roles

  private

  def switch_locale(&action)
    locale = I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def impersonated_roles
    Rails.env.development? ? session[:impersonated_roles] : nil
  end
end
