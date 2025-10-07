module TestidHelpers
  # Find element by test_id attribute (configured via Capybara.test_id)
  def find_by_testid(testid, **options)
    find("[#{Capybara.test_id}='#{testid}']", **options)
  end

  # Click element by test_id attribute
  def click_testid(testid)
    find_by_testid(testid).click
  end

  # Fill in field by test_id attribute
  def fill_testid(testid, with:)
    find_by_testid(testid).set(with)
  end

  # Check if element with testid exists
  def has_testid?(testid)
    has_css?("[#{Capybara.test_id}='#{testid}']")
  end

  # Check if element with testid does not exist
  def has_no_testid?(testid)
    has_no_css?("[#{Capybara.test_id}='#{testid}']")
  end
end

# Add custom RSpec matchers for testid
RSpec::Matchers.define :have_testid do |testid|
  match do |page|
    page.has_css?("[#{Capybara.test_id}='#{testid}']")
  end

  failure_message do |page|
    "expected to find element with #{Capybara.test_id}='#{testid}'"
  end

  failure_message_when_negated do |page|
    "expected not to find element with #{Capybara.test_id}='#{testid}'"
  end
end

RSpec::Matchers.define :have_no_testid do |testid|
  match do |page|
    page.has_no_css?("[#{Capybara.test_id}='#{testid}']")
  end

  failure_message do |page|
    "expected not to find element with #{Capybara.test_id}='#{testid}', but it was found"
  end

  failure_message_when_negated do |page|
    "expected to find element with #{Capybara.test_id}='#{testid}'"
  end
end

RSpec.configure do |config|
  config.include TestidHelpers, type: :system
end
