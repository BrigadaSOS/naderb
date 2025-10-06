# Add custom flash types for toasts
Rails.application.config.to_prepare do
  # Add custom flash types to ActionController
  ActionController::Base.add_flash_types :success, :info, :warning, :danger, :error
end
