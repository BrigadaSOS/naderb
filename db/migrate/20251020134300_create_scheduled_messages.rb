class CreateScheduledMessages < ActiveRecord::Migration[8.0]
  def up
    # Drop existing tables (they should be empty since this is new functionality)
    drop_table :scheduled_message_executions if table_exists?(:scheduled_message_executions)
    drop_table :sent_notifications if table_exists?(:sent_notifications)
    drop_table :scheduled_messages if table_exists?(:scheduled_messages)

    # Recreate scheduled_messages with auto-increment integer ID
    create_table :scheduled_messages do |t|
      t.string :name, null: false
      t.text :description
      t.text :template, null: false
      t.string :schedule, null: false
      t.string :data_query
      t.string :consumer_type, null: false, default: "discord"
      t.string :timezone, null: false, default: "America/Mexico_City"
      t.boolean :enabled, null: false, default: true
      t.string :channel_id, null: false
      t.datetime :next_run_at
      t.binary :created_by_id, limit: 16, null: false

      t.timestamps
    end

    add_index :scheduled_messages, :name, unique: true
    add_index :scheduled_messages, :enabled
    add_index :scheduled_messages, :consumer_type
    add_index :scheduled_messages, :next_run_at
    add_foreign_key :scheduled_messages, :users, column: :created_by_id

    # Recreate sent_notifications with auto-increment integer ID
    create_table :sent_notifications do |t|
      t.integer :scheduled_message_id, null: false
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :sent_notifications, [:scheduled_message_id, :sent_at],
              name: "index_sent_notifications_unique", unique: true
    add_foreign_key :sent_notifications, :scheduled_messages

    # Recreate scheduled_message_executions with auto-increment integer ID
    create_table :scheduled_message_executions do |t|
      t.integer :scheduled_message_id, null: false
      t.datetime :executed_at, null: false
      t.string :status, null: false
      t.string :consumer_type, null: false
      t.string :execution_type, null: false, default: "scheduled"
      t.text :result_data

      t.timestamps
    end

    add_index :scheduled_message_executions, :scheduled_message_id
    add_index :scheduled_message_executions, :executed_at
    add_index :scheduled_message_executions, :status
    add_index :scheduled_message_executions, :execution_type
    add_foreign_key :scheduled_message_executions, :scheduled_messages
  end

  def down
    drop_table :scheduled_message_executions
    drop_table :sent_notifications
    drop_table :scheduled_messages
  end
end
