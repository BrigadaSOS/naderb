class BotChannel < ApplicationCable::Channel
  def subscribed
    stream_from "bot_updates"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end
end
