class MarketDataChannel < ApplicationCable::Channel
  def subscribed
    stream_from "market_data_updates"
  end
end
