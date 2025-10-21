class AddExecutionTypeToScheduledMessageExecutions < ActiveRecord::Migration[8.0]
  def change
    add_column :scheduled_message_executions, :execution_type, :string, null: false, default: "scheduled"
    add_index :scheduled_message_executions, :execution_type
  end
end
