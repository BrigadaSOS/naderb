class AddDiscordOnlyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :discord_only, :boolean, default: false, null: false
    add_index :users, :discord_uid unless index_exists?(:users, :discord_uid)
  end
end
