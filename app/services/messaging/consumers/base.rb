module Messaging::Consumers
  class Base
    # Abstract method to be implemented by subclasses
    # @param message_content [String] The plain text message to send
    # @param channel_id [String] The destination channel/recipient ID
    # @return [Hash] { success: Boolean, details: Hash }
    def deliver(message_content, channel_id)
      raise NotImplementedError, "#{self.class} must implement #deliver"
    end

    # Get the consumer type name (e.g., "discord", "email")
    def consumer_type
      self.class.name.demodulize.underscore.gsub("_consumer", "")
    end
  end
end
