module Messaging::Consumers
  class DiscordConsumer < Base
    # Deliver message to Discord channel via HTTP API
    # @param message_content [String] Plain text message to send
    # @param channel_id [String] Discord channel ID
    # @return [Hash] { success: Boolean, details: Hash }
    def deliver(message_content, channel_id)
      begin
        api_service = Discord::Api::BotService.new
        result = api_service.send_message(channel_id, message_content)

        if result[:success]
          {
            success: true,
            details: {
              message_id: result[:message_id],
              channel_id: channel_id,
              sent_at: Time.current.iso8601
            }
          }
        else
          {
            success: false,
            details: {
              error: result[:error] || "Failed to send message",
              message: result[:message] || "Unknown error",
              channel_id: channel_id
            }
          }
        end
      rescue => e
        Rails.logger.error "Discord message delivery failed: #{e.message}\n#{e.backtrace.join("\n")}"

        {
          success: false,
          details: {
            error: e.class.name,
            message: e.message,
            channel_id: channel_id
          }
        }
      end
    end
  end
end
