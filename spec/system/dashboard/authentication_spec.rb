require 'rails_helper'

RSpec.describe "Dashboard Authentication", type: :system do
  let(:user) { create(:user) }

  describe "accessing dashboard" do
    context "when not logged in" do
      it "redirects to home page" do
        visit dashboard_path

        expect(page).to have_current_path(root_path)
      end
    end

    context "when logged in" do
      before do
        setup_discord_settings
        stub_discord_member(server_id: Setting.discord_server_id, user_id: user.discord_uid, roles: [])

        # Use Warden helper to sign in without going through the UI
        login_as(user, scope: :user)
      end

      it "shows the dashboard" do
        visit dashboard_path

        expect(page).to have_current_path(dashboard_path)
        # Add assertions based on what should be visible in your dashboard
        # For example:
        # expect(page).to have_content("Dashboard")
      end

      it "can sign out" do
        visit dashboard_path

        # Assuming you have a sign out link/button
        # click_on "Sign Out"
        # expect(page).to have_current_path(root_path)

        # Or test the sign out endpoint directly
        page.driver.submit :delete, "/users/sign_out", {}

        visit dashboard_path
        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe "Discord OAuth authentication" do
    # For Discord OAuth, you'll want to mock the OmniAuth callback
    # Here's a basic example:

    before do
      setup_omniauth_discord_mock
    end

    after do
      teardown_omniauth_mock
    end

    it "creates a new user from Discord OAuth", js: true do
      # Setup mock and get the auth hash
      setup_omniauth_discord_mock
      auth_hash = discord_auth_hash

      # Stub Discord API for the created user
      stub_discord_guilds(server_id: Setting.discord_server_id, in_server: true)
      stub_discord_member(server_id: Setting.discord_server_id, user_id: auth_hash[:uid], roles: [])

      expect {
        # Simulate the OAuth callback
        post user_discord_omniauth_callback_path
      }.to change(User, :count).by(1)

      # Verify the user was created with Discord data
      user = User.find_by(discord_uid: auth_hash[:uid])
      expect(user).to be_present
      expect(user.provider).to eq("discord")
    end
  end
end
