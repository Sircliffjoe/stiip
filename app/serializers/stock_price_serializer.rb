class StockPriceSerializer
  include JSONAPI::Serializer
  attributes :date, :open, :high, :low, :close, :volume
end
