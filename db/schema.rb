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

ActiveRecord::Schema[8.0].define(version: 2025_10_21_115706) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.binary "record_id", limit: 16, null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "scheduled_message_executions", force: :cascade do |t|
    t.integer "scheduled_message_id", null: false
    t.datetime "executed_at", null: false
    t.string "status", null: false
    t.string "consumer_type", null: false
    t.text "result_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["executed_at"], name: "index_scheduled_message_executions_on_executed_at"
    t.index ["scheduled_message_id"], name: "index_scheduled_message_executions_on_scheduled_message_id"
    t.index ["status"], name: "index_scheduled_message_executions_on_status"
  end

  create_table "scheduled_messages", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.text "template", null: false
    t.string "schedule", null: false
    t.string "data_query"
    t.string "consumer_type", default: "discord", null: false
    t.string "timezone", default: "America/Mexico_City", null: false
    t.boolean "enabled", default: true, null: false
    t.string "channel_id", null: false
    t.text "conditions"
    t.binary "created_by_id", limit: 16, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consumer_type"], name: "index_scheduled_messages_on_consumer_type"
    t.index ["enabled"], name: "index_scheduled_messages_on_enabled"
    t.index ["name"], name: "index_scheduled_messages_on_name", unique: true
  end

  create_table "sent_notifications", force: :cascade do |t|
    t.integer "scheduled_message_id", null: false
    t.datetime "sent_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scheduled_message_id", "sent_at"], name: "index_sent_notifications_unique", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "tags", id: { type: :binary, limit: 16 }, force: :cascade do |t|
    t.binary "user_id", limit: 16, null: false
    t.string "guild_id", null: false
    t.string "name", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "original_image_url"
    t.text "discord_cdn_url"
    t.index ["id"], name: "index_tags_on_id", unique: true
    t.index ["name", "guild_id"], name: "index_tags_on_name_and_guild_id", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "users", id: { type: :binary, limit: 16 }, force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password"
    t.string "username"
    t.string "provider", null: false
    t.string "display_name"
    t.string "profile_image_url"
    t.datetime "discord_joined_at"
    t.string "discord_uid", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "discord_access_token"
    t.string "discord_refresh_token"
    t.datetime "discord_token_expires_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
    t.integer "birthday_month"
    t.integer "birthday_day"
    t.index ["active"], name: "index_users_on_active"
    t.index ["discord_uid"], name: "index_users_on_discord_uid", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["id"], name: "index_users_on_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "scheduled_message_executions", "scheduled_messages"
  add_foreign_key "scheduled_messages", "users", column: "created_by_id"
  add_foreign_key "sent_notifications", "scheduled_messages"
end
