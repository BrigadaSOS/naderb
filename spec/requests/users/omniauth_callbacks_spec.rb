require 'rails_helper'

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  before do
    setup_discord_settings
  end

  after do
    teardown_omniauth_mock
  end

  describe "POST /users/auth/discord/callback" do
    context "with valid Discord OAuth response" do
      context "when user is in required Discord server" do
        before do
          setup_omniauth_discord_mock
          stub_discord_guilds(server_id: Setting.discord_server_id, in_server: true)
          stub_discord_member(server_id: Setting.discord_server_id, roles: ["member_role"])
        end

        context "for a new user" do
          it "creates a new user and signs them in" do
            expect {
              post user_discord_omniauth_callback_path
            }.to change(User, :count).by(1)

            expect(response).to redirect_to(root_path)

            user = User.last
            expect(user.provider).to eq("discord")
            expect(user.discord_uid).to be_present
            expect(user.username).to be_present
          end
        end

        context "for an existing user" do
          let!(:existing_user) { create(:user, discord_uid: "123456789") }

          before do
            setup_omniauth_discord_mock(uid: "123456789")
          end

          it "updates the existing user and signs them in" do
            expect {
              post user_discord_omniauth_callback_path
            }.not_to change(User, :count)

            expect(response).to redirect_to(root_path)

            existing_user.reload
            expect(existing_user.discord_access_token).to be_present
          end

          it "updates user credentials from OAuth response" do
            post user_discord_omniauth_callback_path

            existing_user.reload
            auth_hash = discord_auth_hash
            expect(existing_user.discord_access_token).to eq(auth_hash[:credentials][:token])
            expect(existing_user.discord_refresh_token).to eq(auth_hash[:credentials][:refresh_token])
          end
        end
      end

      context "when user is NOT in required Discord server" do
        before do
          setup_omniauth_discord_mock
          stub_discord_guilds(server_id: Setting.discord_server_id, in_server: false)
        end

        it "redirects to root with join_server_required flag" do
          post user_discord_omniauth_callback_path

          expect(response).to redirect_to(root_path(join_server_required: true))
          expect(session[:discord_invite_url]).to eq(Setting.discord_server_invite_url)
        end

        it "does not sign the user in" do
          post user_discord_omniauth_callback_path

          expect(controller.current_user).to be_nil
        end
      end
    end

    context "with OAuth failure" do
      before do
        setup_omniauth_failure
      end

      it "redirects to root with error message" do
        get "/users/auth/discord/callback", params: { message: "invalid_credentials" }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Authentication failed.")
      end

      it "does not create a user" do
        expect {
          get "/users/auth/discord/callback", params: { message: "access_denied" }
        }.not_to change(User, :count)
      end
    end

    context "with access_denied error" do
      before do
        setup_omniauth_failure(error: :access_denied)
      end

      it "handles user cancellation gracefully" do
        get "/users/auth/discord/callback", params: {
          message: "access_denied",
          error_reason: "user_denied",
          error_description: "The user denied your request"
        }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Authentication failed.")
      end
    end
  end
end
