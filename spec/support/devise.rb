# frozen_string_literal: true

RSpec.configure do |config|
  # For controller specs
  config.include Devise::Test::ControllerHelpers, type: :controller

  # For request specs
  config.include Devise::Test::IntegrationHelpers, type: :request

  # For system specs, we need to sign in through the UI or use a helper
  config.include Devise::Test::IntegrationHelpers, type: :system

  # Helper method to sign in a user in system tests
  # You can either use this helper or go through the actual sign-in form
  def sign_in_as(user)
    if respond_to?(:sign_in) # For request/controller specs
      sign_in(user)
    else # For system specs, use Warden test helpers
      login_as(user, scope: :user)
    end
  end
end

# Include Warden test helpers for system specs
RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :system

  config.after(type: :system) do
    Warden.test_reset!
  end
end
