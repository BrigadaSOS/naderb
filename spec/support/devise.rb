# frozen_string_literal: true

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  def sign_in_as(user)
    if respond_to?(:sign_in)
      sign_in(user)
    else
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
