class DropDiscordAttachments < ActiveRecord::Migration[8.0]
  def change
    drop_table :discord_attachments, if_exists: true do |t|
      t.string :original_url, null: false
      t.string :discord_channel_id
      t.string :discord_message_id
      t.string :filename
      t.integer :status, default: 0, null: false
      t.text :error_message
      t.datetime :downloaded_at
      t.timestamps

      t.index :original_url, unique: true
      t.index :status
    end
  end
end
