class Dashboard::ProfileController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def update
    if current_user.update(locale_params)
      session[:locale] = locale_params[:locale]
      I18n.locale = locale_params[:locale]
      redirect_to dashboard_profile_index_path, notice: t(".language_updated")
    else
      redirect_to dashboard_profile_index_path, alert: t(".language_update_failed")
    end
  end

  private

  def locale_params
    params.permit(:locale)
  end
end
