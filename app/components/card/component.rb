class Card::Component < ViewComponent::Base
  def initialize(title: nil, subtitle: nil, padding: true)
    @title = title
    @subtitle = subtitle
    @padding = padding
  end
end
