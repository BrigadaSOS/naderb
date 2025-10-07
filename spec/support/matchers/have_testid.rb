module Matchers
  RSpec::Matchers.define :have_test_id do |test_id, on_element: '*', wait: Capybara.default_max_wait_time|
    match do |page|
      page.has_css?("#{on_element}[#{Capybara.test_id}='#{test_id}']", match: :first, wait: wait)
    end

    match_when_negated do |page|
      page.has_no_css?("#{on_element}[#{Capybara.test_id}='#{test_id}']", match: :first, wait: wait)
    end

    failure_message do |_page|
      "expected to find #{on_element} element with test id '#{test_id}' but there were none."
    end

    failure_message_when_negated do |_page|
      "expected not to find #{on_element} element with test id '#{test_id}' but it did."
    end
  end
end
