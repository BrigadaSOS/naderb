# spec/support/helpers/test_id_helpers.rb
module TestIdHelpers
  def find_test_id(value, **options)
    find(test_id_selector(value), **options)
  end

  def within_test_id(value, **options, &block)
    within(test_id_selector(value), **options, &block)
  end

  def test_id_selector(value, on_element: '*')
    "#{on_element}[#{Capybara.test_id}='#{value}']"
  end
end

RSpec.configure do |config|
  config.include TestIdHelpers, type: :feature
end
