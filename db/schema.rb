# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_02_130532) do
  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "guild_id", null: false
    t.integer "user_id", null: false
    t.string "name", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "guild_id"], name: "index_tags_on_name_and_guild_id", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "username"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "provider"
    t.string "discord_uid"
    t.string "discord_access_token"
    t.string "discord_refresh_token"
    t.datetime "discord_token_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "discord_only", default: false, null: false
    t.integer "role", default: 0, null: false
    t.index ["discord_uid"], name: "index_users_on_discord_uid", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "discord_uid"], name: "index_users_on_provider_and_discord_uid", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "tags", "users"
end
