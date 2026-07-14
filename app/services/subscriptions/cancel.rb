module Subscriptions
  class Cancel
    def initialize(payload)
      @payload = payload
    end

    def call
      email = @payload.dig('customer', 'email')
      user = User.find_by(email: email)
      return unless user

      subscription = user.subscription
      return unless subscription

      subscription.update!(status: :cancelled)
      user.free_role!

      Notification.create!(
        user: user,
        title: "Subscription Cancelled",
        body: "Your Premium subscription has been cancelled. You still have access until #{subscription.expires_at&.strftime('%B %d, %Y')}.",
        notification_type: "info"
      )
    end
  end
end
