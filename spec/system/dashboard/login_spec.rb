require 'rails_helper'

RSpec.describe "Dashboard Login", type: :system do
  let(:user) { create(:user, discord_uid: "123456789", discord_access_token: "valid_token") }
  let(:admin_role_id) { "123456" }
  let(:moderator_role_id) { "789012" }
  let(:server_id) { "999888777" }

  before do
    setup_discord_settings(
      server_id: server_id,
      admin_roles: [ admin_role_id ],
      moderator_roles: [ moderator_role_id ]
    )
  end

  describe "user without required roles" do
    before do
      stub_discord_member(server_id: server_id, roles: [])
    end

    it "does not see the Admin section in sidebar", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should see regular sections
      expect(page).to have_testid("sidebar-profile-link")
      expect(page).to have_testid("sidebar-tags-link")

      # Should NOT see Admin section
      expect(page).to have_no_testid("sidebar-admin-section")
    end
  end

  describe "user with admin role" do
    before do
      stub_discord_member(server_id: server_id, roles: [ admin_role_id ])
    end

    it "sees the Admin section in sidebar", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should see regular sections
      expect(page).to have_testid("sidebar-profile-link")
      expect(page).to have_testid("sidebar-tags-link")

      # Should see Admin section
      expect(page).to have_testid("sidebar-admin-section")
      expect(page).to have_testid("sidebar-config-link")
      expect(page).to have_testid("sidebar-data-link")
      expect(page).to have_testid("sidebar-bot-link")
    end
  end

  describe "user with moderator role" do
    before do
      stub_discord_member(server_id: server_id, roles: [ moderator_role_id ])
    end

    it "does not see Admin section (moderator is not admin)", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should see regular sections
      expect(page).to have_testid("sidebar-profile-link")
      expect(page).to have_testid("sidebar-tags-link")

      # Should NOT see Admin section (moderator != admin)
      expect(page).to have_no_testid("sidebar-admin-section")
    end
  end

  describe "user with multiple roles" do
    before do
      stub_discord_member(
        server_id: server_id,
        roles: [ admin_role_id, moderator_role_id, "some_other_role_id" ]
      )
    end

    it "sees Admin section (has admin role)", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should see everything including Admin section
      expect(page).to have_testid("sidebar-profile-link")
      expect(page).to have_testid("sidebar-tags-link")
      expect(page).to have_testid("sidebar-admin-section")
      expect(page).to have_testid("sidebar-config-link")
      expect(page).to have_testid("sidebar-data-link")
      expect(page).to have_testid("sidebar-bot-link")
    end
  end

  describe "when Discord API fails" do
    before do
      stub_discord_api_failure
    end

    it "gracefully handles API failure and shows no admin section", js: true do
      login_as(user, scope: :user)

      visit dashboard_path

      expect(page).to have_current_path(dashboard_path)

      # Should still load the page with basic sections
      expect(page).to have_testid("sidebar-profile-link")
      expect(page).to have_testid("sidebar-tags-link")

      # Should NOT see Admin section (no roles returned)
      expect(page).to have_no_testid("sidebar-admin-section")
    end
  end
end
