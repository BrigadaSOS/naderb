module ApplicationHelper
  def discord_icon(css_class = "w-6 h-6")
    content_tag :svg, class: css_class, fill: "currentColor", viewBox: "0 0 24 24" do
      content_tag :path, "", d: "M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419-.0189 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1568 2.4189Z"
    end
  end

  def discord_button(text, action = nil, html_options: {})
    base_classes = "inline-flex items-center justify-center px-6 py-3 text-white font-semibold rounded-lg transition-colors duration-200"
    color_classes = "bg-indigo-600 hover:bg-indigo-700"
    css_classes = "#{base_classes} #{color_classes} #{html_options[:class]}"

    icon_html = discord_icon("w-6 h-6 mr-2")

    if action&.start_with?("http")
      # External link
      link_to action, class: css_classes, target: "_blank", rel: "noopener noreferrer" do
        icon_html + text
      end
    else
      # Rails route
      button_to action, method: :post, data: { turbo: false }, class: css_classes do
        icon_html + text
      end
    end
  end

  def time_ago_in_words_detailed(from_time)
    return "" unless from_time

    distance = Time.current - from_time
    days = (distance / 1.day).floor
    years = days / 365
    remaining_days = days % 365
    months = remaining_days / 30
    remaining_days = remaining_days % 30

    parts = []
    parts << "#{years} #{'year'.pluralize(years)}" if years > 0
    parts << "#{months} #{'month'.pluralize(months)}" if months > 0
    parts << "#{remaining_days} #{'day'.pluralize(remaining_days)}" if remaining_days > 0 && years == 0

    parts.any? ? "(#{parts.join(' ')} ago)" : "(less than a day ago)"
  end

  def button_classes(variant = :primary, additional_classes = nil)
    base_classes = "px-4 py-2 rounded transition-colors"

    variant_classes = case variant.to_sym
    when :primary
      "bg-primary hover:bg-primary/90 text-primary-foreground"
    when :secondary
      "bg-secondary hover:bg-secondary/90 text-secondary-foreground"
    when :danger
      "bg-destructive hover:bg-destructive/90 text-destructive-foreground"
    when :success
      "bg-accent hover:bg-accent/90 text-accent-foreground"
    else
      "bg-muted hover:bg-muted/90 text-foreground"
    end

    [base_classes, variant_classes, additional_classes].compact.join(" ")
  end

  def button_link(text, path, variant: :primary, data: {}, html_options: {})
    css_classes = button_classes(variant, html_options[:class])
    link_to text, path, data: data, class: css_classes
  end

  # Toast notification helpers
  def toast_container
    tag.div id: "toast_container", class: "fixed bottom-4 right-4 z-50 space-y-4 max-w-xs w-full" do
      # Render flash messages only if they exist (for page loads)
      render(partial: "shared/toast_notification") if flash.any?
    end
  end

  def notification_classes(type)
    base_classes = "relative flex items-center p-4 mb-4 text-sm border-l-4 rounded-lg shadow-lg"
    normalized_type = normalize_flash_type(type)

    case normalized_type
    when "notice"
      "#{base_classes} text-green-800 bg-green-50 border-green-300 dark:text-green-400 dark:bg-gray-800 dark:border-green-800"
    when "alert"
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
    normalized_type = normalize_flash_type(type)

    case normalized_type
    when "notice"
      content_tag :svg, class: "flex-shrink-0 w-4 h-4", fill: "currentColor", viewBox: "0 0 20 20" do
        content_tag :path, "", "fill-rule": "evenodd", d: "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z", "clip-rule": "evenodd"
      end
    when "alert"
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

  private

  def normalize_flash_type(type)
    case type.to_s
    when "notice", "success" then "notice"
    when "alert", "error", "danger" then "alert"
    when "warning" then "warning"
    else "info"
    end
  end
end
