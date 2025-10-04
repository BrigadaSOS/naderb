# Sync environment variables to Settings on app initialization
Rails.application.config.after_initialize do
  Setting.sync_from_env! if ActiveRecord::Base.connection.table_exists?("settings")
end
