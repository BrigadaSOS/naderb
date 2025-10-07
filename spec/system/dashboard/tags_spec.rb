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

  # Shared examples for testing with and without JavaScript
  shared_examples "viewing tags" do
    it "displays all tags" do
      visit dashboard_server_tags_path

      expect(page).to have_content("welcome")
      expect(page).to have_content("rules")
    end

    it "navigates to edit page when clicking own tag" do
      visit dashboard_server_tags_path

      click_on "tag-welcome"

      expect(page).to have_current_path(edit_dashboard_server_tag_path(my_tag))
      expect(page).to have_content("Welcome message")
    end

    it "navigates to show page when clicking other user's tag" do
      visit dashboard_server_tags_path

      click_on "tag-rules"

      expect(page).to have_current_path(dashboard_server_tag_path(other_tag))
      expect(page).to have_test_id("tag-content-input")
    end
  end

  shared_examples "creating tags as trusted user" do |js_enabled|
    it "creates a new tag successfully" do
      visit dashboard_server_tags_path

      click_on "new-tag-button"
      expect(page).to have_current_path(new_dashboard_server_tag_path)

      fill_in "tag-name-input", with: "test_tag"
      fill_in "tag-content-input", with: "This is test content"

      expect(page).to have_test_id("submit-tag-button")
      click_on "submit-tag-button"

      if js_enabled
        # With JS, wait for Turbo to redirect
        expect(page).to have_test_id("tag-test_tag", wait: 5)
        expect(page).to have_current_path(dashboard_server_tags_path)
      else
        expect(page).to have_current_path(dashboard_server_tags_path)
        expect(page).to have_test_id("tag-test_tag")
      end

      expect(Tag.count).to eq(1)
      expect(Tag.last.name).to eq("test_tag")
    end

    it "normalizes tag name to lowercase" do
      visit new_dashboard_server_tag_path

      fill_in "tag-name-input", with: "UPPERCASE_TAG"
      fill_in "tag-content-input", with: "Content"

      click_on "submit-tag-button"

      if js_enabled
        sleep 0.5  # Wait for Turbo submission
      end

      tag = Tag.last
      expect(tag.name).to eq("uppercase_tag")
    end
  end

  shared_examples "editing tags as owner" do |js_enabled|
    it "can edit own tag" do
      visit edit_dashboard_server_tag_path(my_tag)

      fill_in "tag-content-input", with: "Updated content"
      click_on "submit-tag-button"

      if js_enabled
        # With JS, stays on same "page" (Turbo Frame)
        expect(page).to have_content("Updated content", wait: 3)
      else
        # Without JS, redirects to index
        expect(page).to have_current_path(dashboard_server_tags_path)
      end

      expect(my_tag.reload.content).to eq("Updated content")
    end

    it "cannot access edit page for other user's tag" do
      visit edit_dashboard_server_tag_path(other_tag)

      expect(page).to have_current_path(dashboard_server_tag_path(other_tag))
    end
  end

  shared_examples "editing tags as admin" do |js_enabled|
    it "can edit any tag" do
      visit edit_dashboard_server_tag_path(other_tag)

      fill_in "tag-content-input", with: "Admin updated content"
      click_on "submit-tag-button"

      if js_enabled
        sleep 0.5  # Wait for Turbo submission
      else
        # Without JS, redirects to index
        expect(page).to have_current_path(dashboard_server_tags_path)
      end

      expect(other_tag.reload.content).to eq("Admin updated content")
    end
  end

  shared_examples "deleting tags as owner" do |js_enabled|
    it "can delete own tag" do
      visit edit_dashboard_server_tag_path(my_tag)
      tag_id = my_tag.id

      if js_enabled
        # With JavaScript, confirmation dialog appears
        page.accept_confirm do
          click_on "delete-tag-button"
        end
      else
        # Without JavaScript, no confirmation - just click to delete
        click_on "delete-tag-button"
      end

      # Wait for redirect to index and tag to be removed
      expect(page).to have_current_path(dashboard_server_tags_path, wait: 5)
      expect(page).not_to have_selector("[data-testid='tag-my_tag']", wait: 3)
      expect(Tag.exists?(tag_id)).to be false
    end

    it "cannot delete other user's tag" do
      visit dashboard_server_tag_path(other_tag)

      expect(page).not_to have_test_id("delete-tag-button")
    end
  end

  shared_examples "deleting tags as admin" do |js_enabled|
    it "can delete any tag" do
      visit edit_dashboard_server_tag_path(other_tag)
      tag_id = other_tag.id

      if js_enabled
        # With JavaScript, confirmation dialog appears
        page.accept_confirm do
          click_on "delete-tag-button"
        end
      else
        # Without JavaScript, no confirmation - just click to delete
        click_on "delete-tag-button"
      end

      # Wait for redirect to index
      expect(page).to have_current_path(dashboard_server_tags_path, wait: 5)
      expect(Tag.exists?(tag_id)).to be false
    end
  end

  # Tests with JavaScript enabled
  describe "with JavaScript", js: true do
    describe "viewing tags" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let!(:my_tag) { create(:tag, user: user, name: "welcome", content: "Welcome message") }
      let!(:other_tag) { create(:tag, user: other_user, name: "rules", content: "Server rules") }

      before do
        stub_discord_member(server_id: server_id, roles: [])
        login_as(user, scope: :user)
      end

      include_examples "viewing tags"
    end

    describe "creating tags" do
      context "when user is trusted" do
        let(:user) { create(:user) }

        before do
          stub_discord_member(server_id: server_id, roles: [ trusted_role_id ])
          login_as(user, scope: :user)
        end

        include_examples "creating tags as trusted user", true
      end

      context "when user is NOT trusted" do
        let(:user) { create(:user) }

        before do
          stub_discord_member(server_id: server_id, roles: [])
          login_as(user, scope: :user)
        end

        it "does not show create button" do
          visit dashboard_server_tags_path

          expect(page).not_to have_test_id("new-tag-button")
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

        include_examples "editing tags as owner", true
      end

      context "as admin" do
        before do
          stub_discord_member(server_id: server_id, roles: [ admin_role_id ])
          login_as(user, scope: :user)
        end

        include_examples "editing tags as admin", true
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

        include_examples "deleting tags as owner", true
      end

      context "as admin" do
        before do
          stub_discord_member(server_id: server_id, roles: [ admin_role_id ])
          login_as(user, scope: :user)
        end

        include_examples "deleting tags as admin", true
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

      it "filters tags by search query with debounce" do
        visit dashboard_server_tags_path

        fill_in "search-input", with: "wel"

        # Wait for debounced search and filtering
        expect(page).to have_test_id("tag-welcome", wait: 2)
        expect(page).not_to have_test_id("tag-goodbye")
        expect(page).not_to have_test_id("tag-rules")
      end

      it "preserves search query in URL" do
        visit dashboard_server_tags_path

        fill_in "search-input", with: "rule"

        # Wait for debounced search to update URL and content
        expect(page).to have_test_id("tag-rules", wait: 2)
        sleep 0.5  # Give the JS controller time to update the URL
        expect(current_url).to include("search=rule")
      end

      it "preserves search when editing a tag" do
        visit dashboard_server_tags_path(search: "welcome")

        click_on "tag-welcome"
        fill_in "tag-content-input", with: "Updated"
        click_on "submit-tag-button"

        expect(page).to have_test_id("tag-welcome", wait: 2)
        expect(current_url).to include("search=welcome")
      end

      it "clears results when search is empty" do
        visit dashboard_server_tags_path(search: "welcome")

        # Verify we start with filtered results
        expect(page).to have_test_id("tag-welcome")
        expect(page).not_to have_test_id("tag-goodbye")

        # Use the clear button to clear search
        click_on "clear-search-button"

        # Wait for all tags to appear
        expect(page).to have_test_id("tag-goodbye", wait: 2)
        expect(page).to have_test_id("tag-welcome")
        expect(page).to have_test_id("tag-rules")
      end
    end

    describe "URL navigation" do
      let(:user) { create(:user) }
      let!(:tag) { create(:tag, user: user, name: "test") }

      before do
        stub_discord_member(server_id: server_id, roles: [ trusted_role_id ])
        login_as(user, scope: :user)
      end

      it "updates URL when opening new tag modal" do
        visit dashboard_server_tags_path

        click_on "new-tag-button"

        expect(page).to have_current_path(new_dashboard_server_tag_path)
      end

      it "updates URL when opening edit modal" do
        visit dashboard_server_tags_path

        click_on "tag-test"

        expect(page).to have_current_path(edit_dashboard_server_tag_path(tag))
      end

      it "preserves search in URL when navigating" do
        visit dashboard_server_tags_path(search: "test")

        click_on "tag-test"

        expect(current_url).to include("search=test")
      end
    end
  end

  # Tests without JavaScript (graceful degradation)
  describe "without JavaScript" do
    describe "viewing tags" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let!(:my_tag) { create(:tag, user: user, name: "welcome", content: "Welcome message") }
      let!(:other_tag) { create(:tag, user: other_user, name: "rules", content: "Server rules") }

      before do
        stub_discord_member(server_id: server_id, roles: [])
        login_as(user, scope: :user)
      end

      include_examples "viewing tags"
    end

    describe "creating tags" do
      context "when user is trusted" do
        let(:user) { create(:user) }

        before do
          stub_discord_member(server_id: server_id, roles: [ trusted_role_id ])
          login_as(user, scope: :user)
        end

        include_examples "creating tags as trusted user", false
      end

      context "when user is NOT trusted" do
        let(:user) { create(:user) }

        before do
          stub_discord_member(server_id: server_id, roles: [])
          login_as(user, scope: :user)
        end

        it "does not show create button" do
          visit dashboard_server_tags_path

          expect(page).not_to have_test_id("new-tag-button")
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

        include_examples "editing tags as owner", false
      end

      context "as admin" do
        before do
          stub_discord_member(server_id: server_id, roles: [ admin_role_id ])
          login_as(user, scope: :user)
        end

        include_examples "editing tags as admin", false
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

        include_examples "deleting tags as owner", false
      end

      context "as admin" do
        before do
          stub_discord_member(server_id: server_id, roles: [ admin_role_id ])
          login_as(user, scope: :user)
        end

        include_examples "deleting tags as admin", false
      end
    end
  end
end
