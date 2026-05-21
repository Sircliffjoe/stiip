class EmptyState::Component < ViewComponent::Base
  def initialize(title:, description:, icon: nil)
    @title = title
    @description = description
  end
end
