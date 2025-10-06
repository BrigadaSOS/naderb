module TestidHelpers
  # Find element by data-testid attribute
  def find_by_testid(testid, **options)
    find("[data-testid='#{testid}']", **options)
  end

  # Click element by data-testid attribute
  def click_testid(testid)
    find_by_testid(testid).click
  end

  # Fill in field by data-testid attribute
  def fill_testid(testid, with:)
    find_by_testid(testid).set(with)
  end

  # Check if element with testid exists
  def has_testid?(testid)
    has_css?("[data-testid='#{testid}']")
  end

  # Check if element with testid does not exist
  def has_no_testid?(testid)
    has_no_css?("[data-testid='#{testid}']")
  end
end

RSpec.configure do |config|
  config.include TestidHelpers, type: :system
end
