# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: false do |t|
      t.binary :id, limit: 16, null: false, index: { unique: true }, primary_key: true

      ## Authenticable
      t.string :email
      t.string :encrypted_password
      t.string :username
      t.string :provider, null: false

      # Discord Profile
      t.string :display_name
      t.string :profile_image_url
      t.datetime :discord_joined_at
      t.string :discord_uid, null: false

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # Discord Tokens
      t.string :discord_access_token
      t.string :discord_refresh_token
      t.datetime :discord_token_expires_at

      # Status
      t.boolean :active, default: true, null: false

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :discord_uid, unique: true
    add_index :users, :active
  end
end
