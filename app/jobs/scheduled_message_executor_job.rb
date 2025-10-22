class ScheduledMessageExecutorJob < ApplicationJob
  queue_as :default

  # Execute all scheduled messages that are due
  def perform
    result = Messaging::Executor.new.execute_due_messages

    if result[:success]
      Rails.logger.info "ScheduledMessageExecutorJob completed successfully. Executions: #{result[:executions].count}"
    else
      Rails.logger.error "ScheduledMessageExecutorJob completed with errors. Executions: #{result[:executions].count}, Errors: #{result[:errors].count}"
    end
  end
end
