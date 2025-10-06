require 'webmock/rspec'

# Allow connections to localhost for Capybara tests
# Disable real HTTP requests except for localhost
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # Reset WebMock stubs before each test
    WebMock.reset!
  end
end
