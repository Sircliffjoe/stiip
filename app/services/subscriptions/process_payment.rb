module Subscriptions
  class ProcessPayment
    def initialize(payload)
      @payload = payload
    end

    def call
      email = @payload.dig('customer', 'email')
      user = User.find_by(email: email)
      return unless user

      subscription = user.subscription || user.build_subscription
      subscription.update!(
        status: :active,
        plan: :premium,
        expires_at: 1.month.from_now
      )
      
      user.premium_role!
      
      # Notify user
      Notifications::Create.new(
        user: user,
        title: "Payment Successful",
        message: "You are now a Premium subscriber!",
        type: "success"
      ).call
    end
  end
end
