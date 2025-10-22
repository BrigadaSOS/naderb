module Messaging
  class Executor
    def initialize
      @data_query_service = Messaging::Messaging::DataQueryService.new
    end

  # Execute all scheduled messages that are due to run
  # @return [Hash] { success: Boolean, executions: Array, errors: Array }
  def execute_due_messages
    Rails.logger.info "Starting scheduled message execution check"

    executions = []
    errors = []

    # Find all scheduled messages that are due to run
    scheduled_messages = ScheduledMessage.due

    Rails.logger.info "Found #{scheduled_messages.count} scheduled messages due to run"

    scheduled_messages.each do |message|
      begin
        # Execute the message (scheduled execution)
        result = execute_message(message, execution_type: "scheduled")
        executions << result

      rescue => e
        error_info = {
          message_id: message.id,
          message_name: message.name,
          error: e.message,
          backtrace: e.backtrace.first(5)
        }
        errors << error_info
        Rails.logger.error "Error executing message '#{message.name}': #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end

    Rails.logger.info "Scheduled message execution completed. Executions: #{executions.count}, Errors: #{errors.count}"

    {
      success: errors.empty?,
      executions: executions,
      errors: errors
    }
  end

  # Execute a specific message
  # @param message [ScheduledMessage] The message to execute
  # @param execution_type [String] Type of execution: "scheduled" or "manual"
  # @return [Hash] Execution result
  def execute_message(message, execution_type: "manual")
    Rails.logger.info "Executing message: #{message.name} (ID: #{message.id})"

    # Wrap execution in a timeout to prevent hanging
    Timeout.timeout(10) do
      execute_message_internal(message, execution_type)
    end
  rescue Timeout::Error => e
    Rails.logger.error "Message execution timed out after 10 seconds: #{message.name}"
    {
      message_id: message.id,
      message_name: message.name,
      status: "error",
      delivery_result: { success: false, error: "Execution timed out after 10 seconds" }
    }
  end

  def execute_message_internal(message, execution_type)
    # Fetch data if a query is specified
    query_data = if message.data_query.present?
      @data_query_service.execute(
        message.data_query,
        date: Time.current,
        timezone: message.timezone
      )
    else
      {}
    end

    # Render the template with query data
    rendered_content = message.render_template(query_data)

    Rails.logger.debug "Rendered message content (#{rendered_content.length} chars)"

    # Skip if template rendered to empty/whitespace
    if rendered_content.strip.empty?
      Rails.logger.info "Message '#{message.name}' skipped due to empty template"

      # Record the skipped execution
      execution = ScheduledMessageExecution.create!(
        scheduled_message: message,
        executed_at: Time.current,
        status: "skipped",
        consumer_type: message.consumer_type,
        execution_type: execution_type,
        result_data: {
          query_data: query_data.except(:birthdays), # Don't store BirthdayDrop objects
          skip_reason: "Template rendered empty (no content to send)"
        }
      )

      # Update next_run_at for the next execution
      message.update_column(:next_run_at, message.calculate_next_run_at(Time.current))

      return {
        message_id: message.id,
        message_name: message.name,
        execution_id: execution.id,
        status: "skipped",
        delivery_result: { success: true, skipped: true, reason: "Template rendered empty" }
      }
    end

    # Get the appropriate consumer
    consumer = get_consumer(message.consumer_type)

    # Deliver the message
    Rails.logger.info "Delivering message to #{message.consumer_type} channel #{message.channel_id}"
    delivery_result = consumer.deliver(rendered_content, message.channel_id)
    Rails.logger.info "Delivery completed with result: #{delivery_result[:success]}"

    # Record the execution
    execution = ScheduledMessageExecution.create!(
      scheduled_message: message,
      executed_at: Time.current,
      status: delivery_result[:success] ? "success" : "error",
      consumer_type: message.consumer_type,
      execution_type: execution_type,
      result_data: {
        query_data: query_data.except(:birthdays), # Don't store BirthdayDrop objects
        delivery_result: delivery_result,
        rendered_content_length: rendered_content.length
      }
    )

    # Update next_run_at for the next execution
    message.update_column(:next_run_at, message.calculate_next_run_at(Time.current))

    Rails.logger.info "Message '#{message.name}' executed: #{execution.status}, next run at: #{message.next_run_at}"

    {
      message_id: message.id,
      message_name: message.name,
      execution_id: execution.id,
      status: execution.status,
      delivery_result: delivery_result
    }
  end

  private

    def get_consumer(consumer_type)
      case consumer_type
      when "discord"
        Messaging::Consumers::DiscordConsumer.new
      else
        raise "Unknown consumer type: #{consumer_type}"
      end
    end
  end
end
