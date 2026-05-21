class Sidebar::Component < ViewComponent::Base
  def initialize(active_nav: nil)
    @active_nav = active_nav
  end
end
