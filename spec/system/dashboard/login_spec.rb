require 'rails_helper'

RSpec.describe "Dashboard Login", type: :system do
  let(:user) { create(:user, discord_uid: "123456789", discord_access_token: "valid_token") }
  let(:admin_role_id) { "123456" }
  let(:moderator_role_id) { "789012" }
  let(:server_id) { "999888777" }

  before do
    # Configure test settings
    Setting.discord_server_id = server_id
    Setting.discord_admin_roles = [admin_role_id]
    Setting.discord_moderator_roles = [moderator_role_id]
    Setting.discord_server_invite_url = "https://discord.gg/test"
  end

  describe "user without required roles" do
    let(:mock_member_response) do
      {
        "roles" => [],
        "joined_at" => "2024-01-01T00:00:00.000000+00:00",
        "user" => {
          "id" => "123456789",
          "username" => "testuser"
        }
      }
    end

    before do
      stub_request(:get, "https://discord.com/api/v10/users/@me/guilds/#{server_id}/member")
        .to_return(status: 200, body: mock_member_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "does not see the Admin section in sidebar", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should see regular sections (case-insensitive)
      expect(page).to have_content("Profile", normalize_ws: true)
      expect(page).to have_text("Tags", normalize_ws: true)

      # Should NOT see Admin section
      expect(page).not_to have_css("h3.text-yellow-400", text: "ADMIN")
    end
  end

  describe "user with admin role" do
    let(:mock_member_response) do
      {
        "roles" => [admin_role_id],
        "joined_at" => "2024-01-01T00:00:00.000000+00:00",
        "user" => {
          "id" => "123456789",
          "username" => "adminuser"
        }
      }
    end

    before do
      stub_request(:get, "https://discord.com/api/v10/users/@me/guilds/#{server_id}/member")
        .to_return(status: 200, body: mock_member_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "sees the Admin section in sidebar", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should see regular sections
      expect(page).to have_content("Profile", normalize_ws: true)
      expect(page).to have_text("Tags", normalize_ws: true)

      # Should see Admin section with yellow heading
      expect(page).to have_css("h3.text-yellow-400", text: "ADMIN")
      expect(page).to have_content("Config")
      expect(page).to have_content("Data")
      expect(page).to have_content("Bot")
    end
  end

  describe "user with moderator role" do
    let(:mock_member_response) do
      {
        "roles" => [moderator_role_id],
        "joined_at" => "2024-01-01T00:00:00.000000+00:00",
        "user" => {
          "id" => "123456789",
          "username" => "moduser"
        }
      }
    end

    before do
      stub_request(:get, "https://discord.com/api/v10/users/@me/guilds/#{server_id}/member")
        .to_return(status: 200, body: mock_member_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "does not see Admin section (moderator is not admin)", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should see regular sections
      expect(page).to have_content("Profile", normalize_ws: true)
      expect(page).to have_text("Tags", normalize_ws: true)

      # Should NOT see Admin section (moderator != admin)
      expect(page).not_to have_css("h3.text-yellow-400", text: "ADMIN")
    end
  end

  describe "user with multiple roles" do
    let(:mock_member_response) do
      {
        "roles" => [
          admin_role_id,
          moderator_role_id,
          "some_other_role_id"
        ],
        "joined_at" => "2024-01-01T00:00:00.000000+00:00",
        "user" => {
          "id" => "123456789",
          "username" => "superuser"
        }
      }
    end

    before do
      stub_request(:get, "https://discord.com/api/v10/users/@me/guilds/#{server_id}/member")
        .to_return(status: 200, body: mock_member_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "sees Admin section (has admin role)", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should see everything including Admin section
      expect(page).to have_content("Profile", normalize_ws: true)
      expect(page).to have_text("Tags", normalize_ws: true)
      expect(page).to have_css("h3.text-yellow-400", text: "ADMIN")
      expect(page).to have_content("Config")
      expect(page).to have_content("Data")
      expect(page).to have_content("Bot")
    end
  end

  describe "when Discord API fails" do
    before do
      stub_request(:get, "https://discord.com/api/v10/users/@me/guilds/#{server_id}/member")
        .to_return(status: 401, body: '{"message": "401: Unauthorized", "code": 0}', headers: { 'Content-Type' => 'application/json' })

      # Stub the fallback guilds endpoint too
      stub_request(:get, "https://discord.com/api/v10/users/@me/guilds")
        .to_return(status: 401, body: '{"message": "401: Unauthorized", "code": 0}', headers: { 'Content-Type' => 'application/json' })
    end

    it "gracefully handles API failure and shows no admin section", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should still load the page with basic sections
      expect(page).to have_content("Profile", normalize_ws: true)
      expect(page).to have_text("Tags", normalize_ws: true)

      # Should NOT see Admin section (no roles returned)
      expect(page).not_to have_css("h3.text-yellow-400", text: "ADMIN")
    end
  end
end
