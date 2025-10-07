module Matchers
  # @!method have_test_id_and_css(test_id, css, on_element: '*')
  # Matcher for testing the presence of an element with a specific test id and specific CSS on a specific HTML element.
  # If on_element is not provided, the matcher will look for the test_id on any kind of element.
  # @param [String] test_id The test id of the element you're looking for.
  # @param [String] css The CSS that the element with the test_id should have.
  # @option on_element [String] The HTML element that should have the test_id.
  # @return [Boolean] Whether or not the element with the test_id and CSS exists on the page.
  RSpec::Matchers.define :have_test_id_and_css do |test_id, css, on_element: '*'|
    match do |page|
      test_id_css = "#{on_element}[#{Capybara.test_id}='#{test_id}']"
      @base_element_exists = page.has_css?(test_id_css, match: :first)
      @element_exists = @base_element_exists && page.has_css?("#{test_id_css}#{css}", match: :first)
    end

    match_when_negated do |page|
      test_id_css = "#{on_element}[#{Capybara.test_id}='#{test_id}']"
      @base_element_exists = page.has_css?(test_id_css, match: :first)
      return true unless @base_element_exists

      @element_exists = page.has_css?("#{test_id_css}#{css}", match: :first)
      !@element_exists
    end

    failure_message do |_page|
      if !@base_element_exists
        "expected to find #{on_element} element with test id '#{test_id}' but there were none."
      elsif !@element_exists
        "expected #{on_element} element with test id '#{test_id}' to have css '#{css}', but it did not."
      end
    end

    failure_message_when_negated do |_page|
      if @base_element_exists
        "expected not to find #{on_element} element with test id '#{test_id}' but it did."
      elsif @element_exists
        "expected #{on_element} element with test id '#{test_id}' not to have css '#{css}', but it did."
      end
    end
  end
end
