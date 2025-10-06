# Testing Quick Reference

## Common Commands

```bash
# Standard test run
bundle exec rspec

# Run specific test
bundle exec rspec spec/system/my_spec.rb
bundle exec rspec spec/system/my_spec.rb:42  # specific line

# Run all system tests
bundle exec rspec spec/system

# Run all model tests
bundle exec rspec spec/models

# Run tests matching pattern
bundle exec rspec spec/system --example "creates tag"
```

## Watch Browser (Like Cypress)

```bash
# Simple - watch browser
bin/rspec-headed spec/system/my_spec.rb

# Debug - browser + Chrome DevTools
bin/rspec-debug spec/system/my_spec.rb

# All system tests with browser
rake spec:headed

# Or using ENV
HEADED=true bundle exec rspec spec/system/my_spec.rb
```

## Rake Tasks

```bash
rake spec:headed           # All system tests, visible browser
rake spec:debug            # All system tests, with inspector
rake spec:show[spec/system/tags_spec.rb]  # Specific test, headed
rake spec:failed           # Re-run only failures
```

## Useful RSpec Flags

```bash
# Run only failures from last run
bundle exec rspec --only-failures

# Run next failure (stops at first failure)
bundle exec rspec --fail-fast

# Show 10 slowest examples
bundle exec rspec --profile 10

# Seed for reproducible random order
bundle exec rspec --seed 12345

# Run in random order (find order-dependent failures)
bundle exec rspec --order random

# Filter by tag
bundle exec rspec --tag js
bundle exec rspec --tag ~slow  # exclude slow tests
```

## In Test Debugging

```ruby
# Pause test and open pry console
binding.pry

# Pause and open Chrome DevTools (needs bin/rspec-debug)
pause_and_inspect

# Take screenshot
save_screenshot("debug.png")
screenshot_fullpage("fullpage.png")

# Slow down to see what's happening
sleep 2

# Print page content
puts page.html
```

## Creating Test Data

```ruby
# Create user
user = create(:user)

# Create with overrides
admin = create(:user, username: "admin")

# Build without saving
user = build(:user)

# Create multiple
users = create_list(:user, 5)

# Create associations
server = create(:server, owner: user)
tag = create(:tag, user: user, server: server)
```

## Common Expectations

```ruby
# Page content
expect(page).to have_content("Welcome")
expect(page).to have_selector("dialog[open]")
expect(page).to have_field("Email")
expect(page).to have_button("Submit")
expect(page).to have_current_path(dashboard_path)
expect(page).to have_link("Sign Out")

# Database
expect(User.count).to eq(1)
expect(user).to be_valid
expect(user.errors[:email]).to be_present

# HTTP (request specs)
expect(response).to have_http_status(:success)
expect(response).to redirect_to(root_path)
```

## Tips

**Fast tests:**
- Only use `js: true` when needed
- Mock external APIs
- Use `build` instead of `create` when possible

**Better debugging:**
- Use `bin/rspec-headed` to watch browser
- Add `binding.pry` to pause execution
- Use `pause_and_inspect` for Chrome DevTools
- Check `tmp/capybara/` for failure screenshots

**Writing good tests:**
- Test user behavior, not implementation
- One assertion per test when possible
- Descriptive test names
- Use `let` for setup, `before` for actions
