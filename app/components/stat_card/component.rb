class StatCard::Component < ViewComponent::Base
  def initialize(title:, value:, trend: nil, icon: nil)
    @title = title
    @value = value
    @trend = trend
    @icon = icon
  end
end
