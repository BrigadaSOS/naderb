class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Toastable

  impersonates :user

  around_action :switch_locale
  before_action :set_impersonated_roles

  private

  def switch_locale(&action)
    locale = extract_locale_from_params || session[:locale] || current_user_locale || I18n.default_locale
    session[:locale] = locale
    I18n.with_locale(locale, &action)
  end

  def extract_locale_from_params
    parsed_locale = params[:locale]
    I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : nil
  end

  def current_user_locale
    current_user&.locale
  end

  def set_impersonated_roles
    return unless current_user && Rails.env.development?

    current_user.impersonated_roles = session[:impersonated_roles]
  end
end
