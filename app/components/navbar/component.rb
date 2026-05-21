class Navbar::Component < ViewComponent::Base
  def initialize(user: nil)
    @user = user
  end
end
