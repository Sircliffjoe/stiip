class DividendCalendarCard::Component < ViewComponent::Base
  def initialize(dividends: [])
    @dividends = dividends
  end
end
