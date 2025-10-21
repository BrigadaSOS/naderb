class RemoveConditionsFromScheduledMessages < ActiveRecord::Migration[8.0]
  def change
    remove_column :scheduled_messages, :conditions, :text
  end
end
