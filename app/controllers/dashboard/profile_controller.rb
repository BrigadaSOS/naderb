class Dashboard::ProfileController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def update
    if current_user.update(profile_params)
      # Only update session locale if locale was changed
      if profile_params[:locale].present?
        session[:locale] = profile_params[:locale]
        I18n.locale = profile_params[:locale]
      end
      redirect_to dashboard_profile_index_path, notice: t(".profile_updated")
    else
      redirect_to dashboard_profile_index_path, alert: t(".profile_update_failed")
    end
  end

  private

  def profile_params
    params.require(:user).permit(:locale, :birthday_month, :birthday_day)
  end
end
