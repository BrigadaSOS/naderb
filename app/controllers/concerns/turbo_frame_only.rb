module TurboFrameOnly
  extend ActiveSupport::Concern

  private

  def require_turbo_frame_request(redirect_path = nil)
    return if turbo_frame_request?

    redirect_path ||= request.referer || root_path
    redirect_to redirect_path and return
  end
end

