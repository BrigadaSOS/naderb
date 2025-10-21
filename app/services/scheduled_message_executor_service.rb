class ScheduledMessageExecutorService
  def initialize
    @data_query_service = DataQueryService.new
  end

  # Execute all scheduled messages that are due to run
  # @return [Hash] { success: Boolean, executions: Array, errors: Array }
  def execute_due_messages
    Rails.logger.info "Starting scheduled message execution check"

    executions = []
    errors = []

    # Find all active scheduled messages
    scheduled_messages = ScheduledMessage.active

    Rails.logger.info "Found #{scheduled_messages.count} active scheduled messages"

    scheduled_messages.each do |message|
      begin
        # Check if this message was already executed recently
        if message.already_executed_recently?
          Rails.logger.debug "Message '#{message.name}' already executed recently, skipping"
          next
        end

        # Execute the message
        result = execute_message(message)
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

  # Manually execute a specific message (for testing)
  # @param message [ScheduledMessage] The message to execute
  # @return [Hash] Execution result
  def execute_message(message)
    Rails.logger.info "Executing message: #{message.name} (ID: #{message.id})"

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

    # Evaluate conditions (if any)
    if message.conditions.present?
      unless evaluate_conditions(message.conditions, query_data)
        Rails.logger.info "Message '#{message.name}' skipped due to conditions not met"

        # Record the skipped execution
        execution = ScheduledMessageExecution.create!(
          scheduled_message: message,
          executed_at: Time.current,
          status: "skipped",
          consumer_type: message.consumer_type,
          result_data: {
            query_data: query_data.except(:birthdays),
            skip_reason: "Conditions not met"
          }
        )

        return {
          message_id: message.id,
          message_name: message.name,
          execution_id: execution.id,
          status: "skipped",
          delivery_result: { success: true, skipped: true, reason: "Conditions not met" }
        }
      end
    end

    # Render the template with query data
    rendered_content = message.render_template(query_data)

    Rails.logger.debug "Rendered message content (#{rendered_content.length} chars)"

    # Get the appropriate consumer
    consumer = get_consumer(message.consumer_type)

    # Deliver the message
    delivery_result = consumer.deliver(rendered_content, message.channel_id)

    # Record the execution
    execution = ScheduledMessageExecution.create!(
      scheduled_message: message,
      executed_at: Time.current,
      status: delivery_result[:success] ? "success" : "error",
      consumer_type: message.consumer_type,
      result_data: {
        query_data: query_data.except(:users), # Don't store full user objects
        delivery_result: delivery_result,
        rendered_content_length: rendered_content.length
      }
    )

    Rails.logger.info "Message '#{message.name}' executed: #{execution.status}"

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
      MessageConsumers::DiscordConsumer.new
    else
      raise "Unknown consumer type: #{consumer_type}"
    end
  end

  # Evaluate conditions using ERB template with query data
  # @param conditions [String] ERB template that should evaluate to true/false
  # @param query_data [Hash] Data from the data query
  # @return [Boolean] true if conditions are met, false otherwise
  def evaluate_conditions(conditions, query_data)
    begin
      # Create a context with the query data
      context = ScheduledMessage::RenderContext.new(query_data)

      # Render the ERB template
      erb = ERB.new(conditions, trim_mode: "-")
      result = erb.result(context.get_binding)

      # The result should be truthy (we'll consider non-empty strings and true as passing)
      case result
      when TrueClass, FalseClass
        result
      when String
        result.strip.downcase == "true"
      when Numeric
        result > 0
      else
        false
      end
    rescue => e
      Rails.logger.error "Error evaluating conditions: #{e.message}"
      # If there's an error evaluating conditions, fail safe and don't send
      false
    end
  end
end
