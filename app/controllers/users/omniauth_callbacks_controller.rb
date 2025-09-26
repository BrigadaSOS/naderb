class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def discord
    auth = request.env["omniauth.auth"]
    access_token = auth.credentials.token

    verification_service = DiscordServerVerificationService.new(access_token)

    unless verification_service.user_in_required_server?
      session[:discord_invite_url] = verification_service.invite_url
      redirect_to root_path(discord_popup: true)
      return
    end

    @user = User.from_omniauth(auth)
    sign_in_and_redirect @user, event: :authentication
  end

  def failure
    redirect_to root_path, alert: "Authentication failed."
  end
end
