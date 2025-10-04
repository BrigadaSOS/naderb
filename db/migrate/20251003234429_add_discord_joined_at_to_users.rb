class AddDiscordJoinedAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :discord_joined_at, :datetime
  end
end
