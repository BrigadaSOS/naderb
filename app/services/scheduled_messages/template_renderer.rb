module ScheduledMessages
  class TemplateRenderer
    # Renders a Liquid template with provided locals
    # Returns plain text output
    #
    # @param template [String] The Liquid template string
    # @param locals [Hash] Variables to pass to the template
    # @param scheduled_message_id [String, Integer] Optional ID for error logging
    # @return [String] The rendered template
    # @raise [RuntimeError] If template rendering fails
    def self.render(template, locals = {}, scheduled_message_id: nil)
      # Liquid requires string keys
      string_locals = locals.deep_stringify_keys

      # Parse and render Liquid template with strict mode
      liquid_template = Liquid::Template.parse(template)
      liquid_template.render(string_locals, strict_variables: true, strict_filters: true)
    rescue Liquid::Error => e
      error_msg = "Liquid template error"
      error_msg += " for message #{scheduled_message_id}" if scheduled_message_id
      error_msg += ": #{e.message}"
      Rails.logger.error error_msg
      raise "Template error: #{e.message}"
    end
  end
end
