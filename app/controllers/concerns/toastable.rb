module Toastable
  extend ActiveSupport::Concern

  # Convenience methods for different notification types
  def toast_success(message, duration: 5000)
    toast_turbo_stream(message, type: :success, duration: duration)
  end

  def toast_error(message, duration: 7000)
    toast_turbo_stream(message, type: :error, duration: duration)
  end

  def toast_warning(message, duration: 6000)
    toast_turbo_stream(message, type: :warning, duration: duration)
  end

  def toast_info(message, duration: 5000)
    toast_turbo_stream(message, type: :info, duration: duration)
  end

  def toast_notification(message, type: :info, duration: 5000, dismissible: true)
    render "shared/toast_notification",
           message: message,
           type: type.to_s,
           duration: duration,
           dismissible: dismissible
  end

  def toast_turbo_stream(message, type: :info, duration: 5000, dismissible: true)
    turbo_stream.append "toast_container",
                        partial: "shared/toast_notification",
                        locals: {
                          message: message,
                          type: type.to_s,
                          duration: duration,
                          dismissible: dismissible,
                          toast_id: "toast_#{Time.current.to_i}_#{rand(1000)}"
                        }
  end

  def notification_classes(type)
    base_classes = "relative flex items-center p-4 mb-4 text-sm border-l-4 rounded-lg shadow-lg"

    case type.to_s
    when "success", "notice"
      "#{base_classes} text-green-800 bg-green-50 border-green-300 dark:text-green-400 dark:bg-gray-800 dark:border-green-800"
    when "error", "alert"
      "#{base_classes} text-red-800 bg-red-50 border-red-300 dark:text-red-400 dark:bg-gray-800 dark:border-red-800"
    when "warning"
      "#{base_classes} text-yellow-800 bg-yellow-50 border-yellow-300 dark:text-yellow-400 dark:bg-gray-800 dark:border-yellow-800"
    when "info"
      "#{base_classes} text-blue-800 bg-blue-50 border-blue-300 dark:text-blue-400 dark:bg-gray-800 dark:border-blue-800"
    else
      "#{base_classes} text-gray-800 bg-gray-50 border-gray-300 dark:text-gray-400 dark:bg-gray-800 dark:border-gray-600"
    end
  end

  def notification_icon(type)
    case type.to_s
    when "success", "notice"
      content_tag :svg, class: "flex-shrink-0 w-4 h-4", fill: "currentColor", viewBox: "0 0 20 20" do
        content_tag :path, "", "fill-rule": "evenodd", d: "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z", "clip-rule": "evenodd"
      end
    when "error", "alert"
      content_tag :svg, class: "flex-shrink-0 w-4 h-4", fill: "currentColor", viewBox: "0 0 20 20" do
        content_tag :path, "", "fill-rule": "evenodd", d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z", "clip-rule": "evenodd"
      end
    when "warning"
      content_tag :svg, class: "flex-shrink-0 w-4 h-4", fill: "currentColor", viewBox: "0 0 20 20" do
        content_tag :path, "", "fill-rule": "evenodd", d: "M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z", "clip-rule": "evenodd"
      end
    when "info"
      content_tag :svg, class: "flex-shrink-0 w-4 h-4", fill: "currentColor", viewBox: "0 0 20 20" do
        content_tag :path, "", "fill-rule": "evenodd", d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5v3a.75.75 0 001.5 0v-3A.75.75 0 009 9z", "clip-rule": "evenodd"
      end
    else
      content_tag :svg, class: "flex-shrink-0 w-4 h-4", fill: "currentColor", viewBox: "0 0 20 20" do
        content_tag :path, "", "fill-rule": "evenodd", d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5v3a.75.75 0 001.5 0v-3A.75.75 0 009 9z", "clip-rule": "evenodd"
      end
    end
  end
end