# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      ## Authenticable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :username

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # Omniauthable
      t.string :provider
      t.string :discord_uid

      # Omniauthable - Discord
      t.string :discord_access_token
      t.string :discord_refresh_token
      t.datetime :discord_token_expires_at

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, [ :provider, :discord_uid ], unique: true
    add_index :users, :discord_uid, unique: true
  end
end
