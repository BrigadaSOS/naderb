class AddNextRunAtToScheduledMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :scheduled_messages, :next_run_at, :datetime
    add_index :scheduled_messages, :next_run_at

    # Backfill next_run_at for existing messages
    reversible do |dir|
      dir.up do
        ScheduledMessage.reset_column_information
        ScheduledMessage.find_each do |message|
          # Calculate initial next_run_at based on schedule
          message.update_column(:next_run_at, message.calculate_next_run_at(Time.current))
        rescue => e
          # If calculation fails, set to 1 hour from now as a safe default
          Rails.logger.warn "Failed to calculate next_run_at for message #{message.id}: #{e.message}"
          message.update_column(:next_run_at, 1.hour.from_now)
        end
      end
    end
  end
end
