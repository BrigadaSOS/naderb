class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def discord
    auth = request.env["omniauth.auth"]

    # Log the complete OAuth response like HTTParty logging
    Rails.logger.info "=== DISCORD OAUTH RESPONSE ==="
    Rails.logger.info "Provider: #{auth.provider}"
    Rails.logger.info "UID: #{auth.uid}"
    Rails.logger.info "User Info: #{auth.info.to_h}"
    Rails.logger.info "Credentials: #{auth.credentials.to_h}"
    Rails.logger.info "Extra Data: #{auth.extra.to_h}" if auth.extra&.any?
    Rails.logger.info "==============================="

    @user = User.from_omniauth(auth)
    discord_service = DiscordApiService.new(discord_uid: @user.discord_uid)

    unless discord_service.user_in_required_server?
      Rails.logger.info "User #{auth.uid} not in required Discord server #{Setting.discord_server_id}, redirecting to join"

      session[:discord_invite_url] = Setting.discord_server_invite_url
      redirect_to root_path join_server_required: true
      return
    end

    # Fetch member info to update discord_joined_at and cache roles
    discord_service.fetch_member_info

    sign_in_and_redirect @user, event: :authentication
  end

  def failure
    Rails.logger.error "Discord OAuth authentication failed"
    Rails.logger.error "Failure message: #{params[:message]}"
    Rails.logger.error "Error reason: #{params[:error_reason]}" if params[:error_reason]
    Rails.logger.error "Error description: #{params[:error_description]}" if params[:error_description]

    redirect_to root_path, alert: "Authentication failed."
  end
end
