class RemoveDiscordOnlyFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :discord_only, :boolean, default: false, null: false
  end
end
