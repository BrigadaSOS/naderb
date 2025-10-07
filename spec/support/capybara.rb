# frozen_string_literal: true

require "capybara/rails"
require "capybara/rspec"
require "capybara/cuprite"
require "capybara-screenshot/rspec"

# ============================================================================
# CAPYBARA CONFIGURATION
# ============================================================================
Capybara.configure do |config|
  config.test_id = "data-testid"
end

# ============================================================================
# STANDARD CAPYBARA-SCREENSHOT CONFIGURATION
# ============================================================================
Capybara::Screenshot.autosave_on_failure = true
Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara.save_path = Rails.root.join("tmp/capybara")

# ============================================================================
# CUPRITE DRIVER CONFIGURATION
# ============================================================================
Capybara.register_driver :cuprite do |app|
  # Environment variables for debugging:
  # HEADLESS=0     - Show browser window
  # SLOWMO=0.5     - Add 0.5s delay between actions
  # INSPECTOR=true - Enable Chrome DevTools (use with pause_and_inspect helper)

  headless = ENV.fetch("HEADLESS", "1") != "0"
  slowmo = ENV.fetch("SLOWMO", "0").to_f

  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1400, 1400 ],
    browser_options: {
      "no-sandbox" => nil,
      "disable-dev-shm-usage" => nil,
      "disable-search-engine-choice-screen" => nil
    },
    inspector: ENV["INSPECTOR"] == "true",
    headless: headless,
    slowmo: slowmo,
    timeout: 10,
    process_timeout: 15,
    js_errors: true
  )
end

# ============================================================================
# RSPEC CONFIGURATION
# ============================================================================
RSpec.configure do |config|
  # Use fast rack_test for non-JS tests
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # Use Cuprite for JS tests with longer wait time for async operations
  config.before(:each, type: :system, js: true) do
    driven_by :cuprite
    Capybara.default_max_wait_time = 5
  end
end

# ============================================================================
# CUSTOM HELPERS
# ============================================================================
module CupriteHelpers
  # Pause test execution and open Chrome DevTools
  # Usage: Run test with INSPECTOR=true, then call pause_and_inspect in your test
  # Open chrome://inspect in Chrome to connect
  def pause_and_inspect
    return unless ENV["INSPECTOR"]

    puts "\n🔍 Test paused. Open chrome://inspect in Chrome to debug."
    puts "Press Enter in terminal to continue...\n"
    page.driver.debug
  end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end
