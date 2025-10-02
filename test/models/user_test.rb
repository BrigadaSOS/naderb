require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user role defaults to user" do
    user = User.new
    assert user.user?
    assert_not user.admin?
  end

  test "can set admin role" do
    user = User.new(role: :admin)
    assert user.admin?
    assert_not user.user?
  end

  test "can_admin? returns true for admin users" do
    admin_user = User.new(role: :admin)
    regular_user = User.new(role: :user)

    assert admin_user.can_admin?
    assert_not regular_user.can_admin?
  end

  test "discord_only users work correctly" do
    discord_user = User.new(discord_only: true)
    web_user = User.new(discord_only: false, email: "test@example.com")

    assert discord_user.discord_only?
    assert_not discord_user.web_enabled?

    assert_not web_user.discord_only?
    assert web_user.web_enabled?
  end

  test "discord role methods work independently from web roles" do
    user = User.new(role: :admin)

    # Mock discord roles method
    user.stub :discord_roles, [ { "id" => "test_role" } ] do
      assert user.has_discord_role?("test_role")
      assert_not user.has_discord_role?("other_role")

      assert user.has_any_discord_role?([ "test_role", "another_role" ])
      assert_not user.has_any_discord_role?([ "other_role", "different_role" ])
    end
  end
end
