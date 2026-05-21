class Alert::Component < ViewComponent::Base
  def initialize(message:, type: :info)
    @message = message
    @type = type
  end
end
