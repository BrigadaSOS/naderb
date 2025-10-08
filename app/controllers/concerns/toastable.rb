module Toastable
  extend ActiveSupport::Concern

  # Renders a toast message for Turbo Stream responses
  def render_toast(flash_type, message, status: :ok)
    flash.now[flash_type] = message
    render turbo_stream: turbo_stream.append("toast_container", partial: "shared/toast_notification"), status: status
  end

  # Renders a Turbo Frame with a toast notification, with HTML fallback
  def render_frame_with_toast(flash_type:, message:, frame_id:, partial:, locals: {}, redirect_path: nil)
    respond_to do |format|
      format.turbo_stream do
        flash.now[flash_type] = message
        response.set_header("Turbo-Location", redirect_path)
        render turbo_stream: [
          toast_stream,
          turbo_stream.replace(frame_id, partial: partial, locals: locals)
        ]
      end
      format.html do
        flash[flash_type] = message
        redirect_to redirect_path, status: :see_other
      end
    end
  end

  private

  # Returns a turbo stream for appending toast notification
  def toast_stream
    turbo_stream.append("toast_container", partial: "shared/toast_notification")
  end
end
