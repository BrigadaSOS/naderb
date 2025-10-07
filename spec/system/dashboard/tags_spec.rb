require 'rails_helper'

RSpec.describe "Dashboard Tags", type: :system do
  let(:admin_role_id) { "123456" }
  let(:trusted_role_id) { "654321" }
  let(:server_id) { "999888777" }

  # Force English locale for consistent testing
  around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end

  before do
    setup_discord_settings(
      server_id: server_id,
      admin_roles: [ admin_role_id ],
      trusted_user_roles: [ trusted_role_id ]
    )
    stub_discord_guilds(server_id: server_id, in_server: true)
  end

  describe "viewing tags" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:my_tag) { create(:tag, user: user, name: "welcome", content: "Welcome message") }
    let!(:other_tag) { create(:tag, user: other_user, name: "rules", content: "Server rules") }

    before do
      stub_discord_member(server_id: server_id, roles: [])
      login_as(user, scope: :user)
    end

    it "displays all tags", js: true do
      visit dashboard_server_tags_path

      expect(page).to have_content("welcome")
      expect(page).to have_content("rules")
    end

    it "opens edit modal when clicking own tag", js: true do
      visit dashboard_server_tags_path

      click_testid "tag-welcome"

      expect(page).to have_content("Welcome message")
      expect(current_path).to eq(edit_dashboard_server_tag_path(my_tag))
    end

    it "opens show modal when clicking other user's tag", js: true do
      visit dashboard_server_tags_path

      click_testid "tag-rules"

      # Wait for modal to open and become visible
      expect(page).to have_testid("tag-content-input", wait: 2)
      expect(find_by_testid("tag-content-input").value).to eq("Server rules")
      expect(current_path).to eq(dashboard_server_tag_path(other_tag))
    end
  end

  describe "creating tags" do
    context "when user is trusted" do
      let(:user) { create(:user) }

      before do
        stub_discord_member(server_id: server_id, roles: [ trusted_role_id ])
        login_as(user, scope: :user)
      end

      it "creates a new tag successfully", js: true do
        visit dashboard_server_tags_path

        click_testid "new-tag-button"
        expect(current_path).to eq(new_dashboard_server_tag_path)

        fill_testid "tag-name-input", with: "test_tag"
        fill_testid "tag-content-input", with: "This is test content"

        click_testid "submit-tag-button"

        # Wait for tag to appear (which means redirect happened and tag was created)
        expect(page).to have_testid("tag-test_tag", wait: 5)

        # Verify we're back at the index page
        expect(current_path).to eq(dashboard_server_tags_path)

        # Verify tag was created
        expect(Tag.count).to eq(1)
        expect(Tag.last.name).to eq("test_tag")
      end

      it "normalizes tag name to lowercase", js: true do
        visit new_dashboard_server_tag_path

        fill_testid "tag-name-input", with: "UPPERCASE_TAG"
        fill_testid "tag-content-input", with: "Content"

        click_testid "submit-tag-button"

        tag = Tag.last
        expect(tag.name).to eq("uppercase_tag")
      end
    end

    context "when user is NOT trusted" do
      let(:user) { create(:user) }

      before do
        stub_discord_member(server_id: server_id, roles: [])
        login_as(user, scope: :user)
      end

      it "does not show create button", js: true do
        visit dashboard_server_tags_path

        expect(page).to have_no_testid("new-tag-button")
      end
    end
  end

  describe "editing tags" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:my_tag) { create(:tag, user: user, name: "my_tag", content: "My content") }
    let!(:other_tag) { create(:tag, user: other_user, name: "other_tag", content: "Other content") }

    context "as tag owner" do
      before do
        stub_discord_member(server_id: server_id, roles: [ trusted_role_id ])
        login_as(user, scope: :user)
      end

      it "can edit own tag", js: true do
        visit edit_dashboard_server_tag_path(my_tag)

        fill_testid "tag-content-input", with: "Updated content"
        click_testid "submit-tag-button"

        expect(page).to have_content("Updated content")
        expect(my_tag.reload.content).to eq("Updated content")
      end

      it "cannot access edit page for other user's tag", js: true do
        visit edit_dashboard_server_tag_path(other_tag)

        expect(current_path).to eq(dashboard_server_tag_path(other_tag))
      end
    end

    context "as admin" do
      before do
        stub_discord_member(server_id: server_id, roles: [ admin_role_id ])
        login_as(user, scope: :user)
      end

      it "can edit any tag", js: true do
        visit edit_dashboard_server_tag_path(other_tag)

        fill_testid "tag-content-input", with: "Admin updated content"
        click_testid "submit-tag-button"

        expect(other_tag.reload.content).to eq("Admin updated content")
      end
    end
  end

  describe "deleting tags" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:my_tag) { create(:tag, user: user, name: "my_tag") }
    let!(:other_tag) { create(:tag, user: other_user, name: "other_tag") }

    context "as tag owner" do
      before do
        stub_discord_member(server_id: server_id, roles: [ trusted_role_id ])
        login_as(user, scope: :user)
      end

      it "can delete own tag", js: true do
        visit edit_dashboard_server_tag_path(my_tag)

        accept_confirm do
          click_testid "delete-tag-button"
        end

        # Wait for redirect to index and tag to be removed
        expect(current_path).to eq(dashboard_server_tags_path)
        expect(page).to have_no_testid("tag-my_tag", wait: 2)
        expect(Tag.exists?(my_tag.id)).to be false
      end

      it "cannot delete other user's tag", js: true do
        visit dashboard_server_tag_path(other_tag)

        expect(page).to have_no_testid("delete-tag-button")
      end
    end

    context "as admin" do
      before do
        stub_discord_member(server_id: server_id, roles: [ admin_role_id ])
        login_as(user, scope: :user)
      end

      it "can delete any tag", js: true do
        visit edit_dashboard_server_tag_path(other_tag)

        accept_confirm do
          click_testid "delete-tag-button"
        end

        # Wait for redirect to index
        expect(current_path).to eq(dashboard_server_tags_path)
        expect(Tag.exists?(other_tag.id)).to be false
      end
    end
  end

  describe "searching tags" do
    let(:user) { create(:user) }
    let!(:welcome_tag) { create(:tag, user: user, name: "welcome") }
    let!(:goodbye_tag) { create(:tag, user: user, name: "goodbye") }
    let!(:rules_tag) { create(:tag, user: user, name: "rules") }

    before do
      stub_discord_member(server_id: server_id, roles: [])
      login_as(user, scope: :user)
    end

    it "filters tags by search query", js: true do
      visit dashboard_server_tags_path

      fill_testid "search-input", with: "wel"

      # Wait for debounced search and filtering
      expect(page).to have_testid("tag-welcome", wait: 2)
      expect(page).to have_no_testid("tag-goodbye")
      expect(page).to have_no_testid("tag-rules")
    end

    it "preserves search query in URL", js: true do
      visit dashboard_server_tags_path

      fill_testid "search-input", with: "rule"

      # Wait for debounced search to update URL and content
      expect(page).to have_testid("tag-rules", wait: 2)
      sleep 0.5  # Give the JS controller time to update the URL
      expect(current_url).to include("search=rule")
    end

    it "preserves search when editing a tag", js: true do
      visit dashboard_server_tags_path(search: "welcome")

      click_testid "tag-welcome"
      fill_testid "tag-content-input", with: "Updated"
      click_testid "submit-tag-button"

      expect(page).to have_testid("tag-welcome", wait: 2)
      expect(current_url).to include("search=welcome")
    end

    it "clears results when search is empty", js: true do
      visit dashboard_server_tags_path(search: "welcome")

      # Verify we start with filtered results
      expect(page).to have_testid("tag-welcome")
      expect(page).to have_no_testid("tag-goodbye")

      # Use the clear button to clear search
      click_testid "clear-search-button"

      # Wait for all tags to appear
      expect(page).to have_testid("tag-goodbye", wait: 2)
      expect(page).to have_testid("tag-welcome")
      expect(page).to have_testid("tag-rules")
    end
  end

  describe "URL navigation" do
    let(:user) { create(:user) }
    let!(:tag) { create(:tag, user: user, name: "test") }

    before do
      stub_discord_member(server_id: server_id, roles: [ trusted_role_id ])
      login_as(user, scope: :user)
    end

    it "updates URL when opening new tag modal", js: true do
      visit dashboard_server_tags_path

      click_testid "new-tag-button"

      expect(current_path).to eq(new_dashboard_server_tag_path)
    end

    it "updates URL when opening edit modal", js: true do
      visit dashboard_server_tags_path

      click_testid "tag-test"

      expect(current_path).to eq(edit_dashboard_server_tag_path(tag))
    end

    it "preserves search in URL when navigating", js: true do
      visit dashboard_server_tags_path(search: "test")

      click_testid "tag-test"

      expect(current_url).to include("search=test")
    end
  end
end
