# RSpec Testing Guide for Nadeshikorb

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific file
bundle exec rspec spec/system/dashboard/authentication_spec.rb

# Run specific test
bundle exec rspec spec/system/dashboard/authentication_spec.rb:23
```

### Watch Browser Like Cypress

**Easy Way (Recommended):**
```bash
# Watch browser in real-time
bin/rspec-headed spec/system/my_spec.rb

# Debug with Chrome DevTools Inspector
bin/rspec-debug spec/system/my_spec.rb

# Or use rake tasks
rake spec:headed           # Run all system tests with visible browser
rake spec:debug            # Run with inspector enabled
rake spec:show[spec/system/my_spec.rb]  # Run specific test with headed mode
```

**Using ENV variables (also works):**
```bash
HEADED=true bundle exec rspec spec/system/my_spec.rb
INSPECTOR=true HEADED=true bundle exec rspec spec/system/my_spec.rb
```

## Authentication in Tests

### System Tests (with UI interaction)

Use the `login_as` helper from Warden:

```ruby
require 'rails_helper'

RSpec.describe "My Feature", type: :system do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  it "does something", js: true do
    visit dashboard_path
    # Your test code...
  end
end
```

### Request/Controller Tests

Use Devise test helpers:

```ruby
require 'rails_helper'

RSpec.describe "API Endpoint", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it "returns success" do
    get dashboard_path
    expect(response).to have_http_status(:success)
  end
end
```

## Testing Discord OAuth

For Discord OAuth flows, mock OmniAuth:

```ruby
before do
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
```

## Testing with JavaScript

Add `js: true` to enable JavaScript testing with Cuprite:

```ruby
it "opens modal", js: true do
  visit dashboard_path
  click_on "New Tag"

  expect(page).to have_selector("dialog[open]")
end
```

## Using FactoryBot

Create test data easily:

```ruby
# Create a user
user = create(:user)

# Create with overrides
admin = create(:user, username: "admin")

# Create without saving (for validation tests)
user = build(:user)

# Create multiple
users = create_list(:user, 5)
```

## Directory Structure

```
spec/
├── factories/           # FactoryBot factories
│   └── users.rb
├── support/             # Test helpers and configuration
│   ├── capybara.rb     # Cuprite configuration
│   ├── devise.rb
│   └── factory_bot.rb
├── system/              # System tests (user workflows)
├── requests/            # Request specs (API/controller tests)
├── models/              # Model specs
└── rails_helper.rb      # Main test configuration
```

## Common Matchers

```ruby
# Page content
expect(page).to have_content("Welcome")
expect(page).to have_current_path(dashboard_path)
expect(page).to have_selector("dialog[open]")
expect(page).to have_field("Name")
expect(page).to have_button("Submit")

# HTTP responses
expect(response).to have_http_status(:success)
expect(response).to redirect_to(root_path)

# Database
expect(User.count).to eq(1)
expect(user).to be_valid
expect(user.errors[:email]).to include("can't be blank")
```

## Debugging Tests

### Watch Browser in Real-Time (like Cypress)

**Easiest way:**
```bash
bin/rspec-headed spec/system/my_test_spec.rb
```

**Or with ENV:**
```bash
HEADED=true bundle exec rspec spec/system/my_test_spec.rb
```

The browser will:
- Open visibly (not headless)
- Run slightly slower for visibility (0.1s delay between actions)
- Show all clicks, form fills, and navigation

### Pause Test Execution

Add `binding.pry` or `pause_and_inspect` in your test:

```ruby
it "does something", js: true do
  visit dashboard_path

  binding.pry  # Test pauses here, browser stays open!

  click_on "New Tag"
end
```

Or use Cuprite's built-in inspector:

```ruby
it "debug with Chrome DevTools", js: true do
  visit dashboard_path

  pause_and_inspect  # Opens Chrome DevTools!
end
```

Run with:
```bash
bin/rspec-debug spec/system/my_test_spec.rb
# Or: INSPECTOR=true HEADED=true bundle exec rspec spec/system/my_test_spec.rb
```

### Slow Down Tests for Visibility

When using `HEADED=true`, tests automatically slow down (0.1s per action) so you can see what's happening.

You can also add explicit sleeps for debugging:
```ruby
click_on "Submit"
sleep 2  # Watch the form submit
expect(page).to have_content("Success")
```

### Take Screenshots

```ruby
# Auto-saved on failure to tmp/capybara/

# Manual screenshot
save_screenshot("tmp/debug.png")

# Full-page screenshot (Cuprite feature)
screenshot_fullpage("tmp/fullpage.png")
```

### Save HTML on Failure

HTML is automatically saved to `tmp/capybara/` when tests fail, along with screenshots.

## Cuprite-Specific Features

### Execute JavaScript

```ruby
# Evaluate JavaScript and get result
result = evaluate_script("return document.title")

# Or use Capybara's built-in
page.evaluate_script("document.querySelector('h1').textContent")
```

### Network Interception

Cuprite can intercept network requests (advanced):

```ruby
page.driver.browser.on(:request) do |request|
  puts "Request: #{request.url}"
end
```

### Custom Browser Options

All configured in `spec/support/capybara.rb`. Current options:
- Window size: 1400x1400
- Headless by default (override with `HEADED=true`)
- Chrome DevTools inspector (enable with `INSPECTOR=true`)
- Slowmo for visibility in headed mode

## Performance Tips

1. **Use `js: true` only when needed** - Non-JS tests use `rack_test` and are much faster
2. **Mock external services** - Discord API calls should be mocked in tests
3. **Use factories efficiently** - Only create the data you need
4. **Database cleaner** - Tests run in transactions by default (fast)
5. **Parallel testing** - Can run tests in parallel with `parallel_tests` gem

## Tips

1. **Keep tests fast**: Mock external services (Discord API, etc.)
2. **Use factories**: Don't create records manually
3. **Test user behavior**: Focus on what users see/do, not implementation
4. **Use descriptive names**: Test names should explain what's being tested
5. **One assertion per test**: Makes failures easier to debug
6. **Use HEADED mode for debugging**: See exactly what the browser does
7. **Use Cuprite helpers**: `pause_and_inspect`, `screenshot_fullpage`, etc.

## Example: Testing a Modal Workflow

```ruby
require 'rails_helper'

RSpec.describe "Tag Management", type: :system do
  let(:user) { create(:user) }
  let(:server) { create(:server) }

  before do
    login_as(user, scope: :user)
  end

  describe "creating a tag", js: true do
    it "opens modal, creates tag, and closes modal" do
      visit dashboard_server_tags_path(server)

      click_on "New Tag"
      expect(page).to have_current_path(new_dashboard_server_tag_path(server))
      expect(page).to have_selector("dialog[open]")

      fill_in "Name", with: "My Tag"
      click_on "Create Tag"

      expect(page).to have_current_path(dashboard_server_tags_path(server))
      expect(page).to have_content("My Tag")
      expect(page).not_to have_selector("dialog[open]")
    end

    it "closes modal and clears search" do
      visit new_dashboard_server_tag_path(server, search: "ruby")

      click_on "Cancel"

      expect(page).to have_current_path(dashboard_server_tags_path(server))
      expect(page).to have_field("search", with: "")
    end

    it "debugs with inspector", js: true do
      visit dashboard_server_tags_path(server)

      # Uncomment to pause and inspect
      # pause_and_inspect

      click_on "New Tag"

      # Take a screenshot
      screenshot_fullpage("tmp/tag_modal.png")
    end
  end
end
```

## CI/CD Setup

Cuprite works great in CI environments. Example GitHub Actions:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.6
          bundler-cache: true

      - name: Install Chrome
        run: |
          wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
          sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
          sudo apt-get update
          sudo apt-get install -y google-chrome-stable

      - name: Run tests
        run: bundle exec rspec

      - name: Upload screenshots on failure
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: capybara-screenshots
          path: tmp/capybara/
```

## Why Cuprite?

We migrated from Selenium to Cuprite because:

- ✅ **Faster** - Uses Chrome DevTools Protocol directly, no WebDriver overhead
- ✅ **Better debugging** - Built-in Chrome Inspector support
- ✅ **More reliable** - Better handling of async JavaScript
- ✅ **Cleaner API** - Direct access to browser features
- ✅ **Screenshots** - Better screenshot capabilities
- ✅ **Created by Evil Martians** - Same team behind many Rails tools

The migration was seamless - all existing tests work without changes!
