module Subscriptions
  class ProcessPayment
    def initialize(payload)
      @payload = payload
    end

    def call
      email = @payload.dig('customer', 'email')
      user = User.find_by(email: email)
      return unless user
      plan = (@payload.dig('metadata', 'plan') || @payload.dig(:metadata, :plan)).to_s.presence_in(%w[premium business_api]) || 'premium'

      subscription = user.subscription || user.build_subscription
      subscription.update!(
        status: :active,
        plan: plan,
        starts_at: Time.current,
        expires_at: 1.month.from_now
      )
      
      user.update!(role: plan)
      
      # Notify user
      Notifications::Create.new(
        user: user,
        title: "Payment Successful",
        message: "You are now a #{plan.titleize} subscriber!",
        type: "success"
      ).call
    end
  end
end
