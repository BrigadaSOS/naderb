class FixActiveStorageForUuidRecords < ActiveRecord::Migration[8.0]
  def up
    # Remove existing data first to avoid conversion issues
    # Use execute to bypass model callbacks that might fail
    execute "DELETE FROM active_storage_attachments"
    execute "DELETE FROM active_storage_blobs"

    # Change record_id to binary to support UUIDs
    # This allows ActiveStorage to work with models that use UUID primary keys
    change_column :active_storage_attachments, :record_id, :binary, limit: 16, null: false
  end

  def down
    # Remove data to avoid conversion issues
    execute "DELETE FROM active_storage_attachments"
    execute "DELETE FROM active_storage_blobs"

    # Revert to bigint
    change_column :active_storage_attachments, :record_id, :bigint, null: false
  end
end
