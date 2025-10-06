require 'rails_helper'

RSpec.describe "Dashboard Authentication", type: :system do
  let(:user) { create(:user) }

  describe "accessing dashboard" do
    context "when not logged in" do
      it "redirects to home page" do
        visit dashboard_path

        # Devise will redirect to root when not authenticated
        # Adjust this based on your actual authentication redirect
        expect(page).to have_current_path(root_path)
      end
    end

    context "when logged in" do
      before do
        # Stub Discord API calls
        stub_request(:get, %r{https://discord.com/api/v10/users/@me/guilds/.*/member})
          .to_return(
            status: 200,
            body: { "roles" => [], "joined_at" => "2024-01-01T00:00:00.000000+00:00" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

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
      # Mock OmniAuth for testing
      OmniAuth.config.test_mode = true

      OmniAuth.config.mock_auth[:discord] = OmniAuth::AuthHash.new({
        provider: 'discord',
        uid: '123456789',
        info: {
          name: 'Test User',
          email: 'test@example.com',
          image: 'https://example.com/avatar.png'
        },
        credentials: {
          token: 'mock_token',
          refresh_token: 'mock_refresh_token',
          expires_at: 1.day.from_now.to_i
        },
        extra: {
          raw_info: {
            global_name: 'Test User Display Name'
          }
        }
      })
    end

    after do
      OmniAuth.config.test_mode = false
    end

    it "creates a new user from Discord OAuth", js: true do
      visit root_path

      # Click your "Sign in with Discord" button
      # The actual selector depends on your UI
      # click_on "Sign in with Discord"

      # In test mode, this will use the mocked auth hash above
      # and redirect to your omniauth callback
      # visit user_discord_omniauth_callback_path

      # Then verify the user was created
      # expect(User.find_by(discord_uid: '123456789')).to be_present
    end
  end
end
