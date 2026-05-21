class StockTicker::Component < ViewComponent::Base
  def initialize(stocks: [])
    @stocks = stocks
  end
end
