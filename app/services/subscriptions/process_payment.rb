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
      reference = @payload["reference"] || @payload[:reference]

      Subscriptions::Activate.new(user: user, plan: plan, payment_reference: reference).call
    end
  end
end
