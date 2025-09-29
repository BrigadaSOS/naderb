class Dashboard::Admin::BotController < ApplicationController
  include WebAuthorization
  before_action :authenticate_user!
  before_action :admin_required!

  def index
  end

  private

  def admin_required!
    require_admin
  end
end