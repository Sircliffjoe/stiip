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

        if verify_response["status"] && verify_response.dig("data", "status") == "success"
          user_id = verify_response.dig("data", "metadata", "user_id")
          user = User.find(user_id)

          # Create or update subscription
          plan = verify_response.dig("data", "metadata", "plan") || "premium"
          plan = plan.to_s.presence_in(%w[premium business_api]) || "premium"

          Subscriptions::Activate.new(user: user, plan: plan, payment_reference: payment_reference).call
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
