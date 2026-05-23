module Webhooks
  class PaystackController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_paystack_signature

    def create
      event = params.permit!
      reference = event.dig(:data, :reference)
      status = event.dig(:data, :status)

      if status == "success"
        payment_reference = reference
        verify_response = PaystackService.verify_payment(payment_reference)

        if verify_response[:status] && verify_response[:data][:status] == "success"
          user_id = verify_response.dig(:data, :metadata, :user_id)
          user = User.find(user_id)

          # Create or update subscription
          subscription = user.subscription || user.build_subscription
          subscription.update!(
            status: :active,
            plan: :premium,
            paystack_reference: payment_reference,
            expires_at: 1.month.from_now
          )

          # Update user role
          user.update!(role: :premium)

          # Create notification
          Notification.create!(
            user: user,
            title: "Welcome to Premium!",
            body: "Your payment was successful. You now have full access to all STIIP features.",
            notification_type: "success"
          )
        end
      end

      head :ok
    end

    private

    def verify_paystack_signature
      secret_key = ENV.fetch("PAYSTACK_SECRET_KEY", "")
      signature = request.headers["X-Paystack-Signature"]
      body = request.raw_post

      expected_signature = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha512"),
        secret_key,
        body
      )

      unless Rack::Utils.secure_compare(signature.to_s, expected_signature)
        head :unauthorized
      end
    end
  end
end
