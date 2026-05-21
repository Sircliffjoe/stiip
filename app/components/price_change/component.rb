class PriceChange::Component < ViewComponent::Base
  def initialize(change:)
    @change = change.to_f
  end
  
  def positive?
    @change >= 0
  end
end
