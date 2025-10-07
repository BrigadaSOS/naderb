module Matchers
  # @!method have_test_id(test_id, on_element: '*')
  # Matcher for testing the presence of an element with a specific test id on a specific HTML element.
  # If on_element is not provided, the matcher will look for the test_id on any kind of element.
  # @param [String] test_id The test id of the element you're looking for.
  # @option on_element [String] The HTML element that should have the test_id.
  # @return [Boolean] Whether or not the element with the test_id exists on the page.
  RSpec::Matchers.define :have_test_id do |test_id, on_element: '*'|
    match do |page|
      @element_exists = page.has_css?("#{on_element}[#{Capybara.test_id}='#{test_id}']", match: :first)
    end

    match_when_negated do |page|
      @element_does_not_exist = page.has_no_css?("#{on_element}[#{Capybara.test_id}='#{test_id}']", match: :first)
    end

    failure_message do |_page|
      "expected to find #{on_element} element with test id '#{test_id}' but there were none."
    end

    failure_message_when_negated do |_page|
      "expected not to find #{on_element} element with test id '#{test_id}' but it did."
    end
  end
end
