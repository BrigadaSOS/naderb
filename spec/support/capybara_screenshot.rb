require 'capybara-screenshot/rspec'

module Capybara
  module Screenshot
    module RSpec
      module FilePathReporter
        extend BaseReporter

        enhance_with_screenshot :example_failed

        def example_failed_with_screenshot(notification)
          example_failed_without_screenshot notification
          output_screenshot_info(notification.example)
        end

        private

        def output_screenshot_info(example)
          return unless (screenshot = example.metadata[:screenshot])
          output.puts("> Screenshot: file://#{screenshot[:image]}") if screenshot[:image]
          output.puts("> HTML: file://#{screenshot[:html]}") if screenshot[:html]
        end
      end
    end
  end
end

# Register the custom reporter for all formatters
Capybara::Screenshot::RSpec::REPORTERS.each_key do |formatter|
  Capybara::Screenshot::RSpec::REPORTERS[formatter] = Capybara::Screenshot::RSpec::FilePathReporter
end
