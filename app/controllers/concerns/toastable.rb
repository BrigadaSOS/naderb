module Toastable
  extend ActiveSupport::Concern
  include NotificationHelper

  # Controller-specific toast methods that work with turbo_stream responses
  def toast_success_response(message, additional_streams: [])
    render turbo_stream: [toast_success(message)] + additional_streams
  end

  def toast_error_response(message, additional_streams: [])
    render turbo_stream: [toast_error(message)] + additional_streams
  end

  def toast_warning_response(message, additional_streams: [])
    render turbo_stream: [toast_warning(message)] + additional_streams
  end

  def toast_info_response(message, additional_streams: [])
    render turbo_stream: [toast_info(message)] + additional_streams
  end

  # Combine multiple turbo streams with a toast
  def render_with_toast(message, type: :info, streams: [])
    toast_stream = case type.to_sym
                   when :success, :notice
                     toast_success(message)
                   when :error, :alert
                     toast_error(message)
                   when :warning
                     toast_warning(message)
                   else
                     toast_info(message)
                   end

    render turbo_stream: [toast_stream] + Array(streams)
  end
end