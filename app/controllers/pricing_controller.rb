class PricingController < ApplicationController
  before_action :authenticate_user!, only: [:checkout]

  def index
    @plans = [
      {
        name: "Free",
        price: 0,
        period: "forever",
        description: "Get started with essential market data",
        features: [
          "1 Watchlist (up to 5 stocks)",
          "30-day price history",
          "Basic dividend calendar",
          "Market news feed",
          "Educational articles",
          "Community access"
        ],
        cta: "Get Started Free",
        cta_path: new_user_registration_path,
        highlighted: false
      },
      {
        name: "Premium",
        price: 2500,
        period: "month",
        description: "Unlock the full power of NoraCapital intelligence",
        features: [
          "Unlimited Watchlists & stocks",
          "Full historical price data",
          "Advanced dividend analytics & yield rankings",
          "Real-time price alerts",
          "CSV data export",
          "Priority support",
          "AI-powered insights (coming soon)"
        ],
        cta: "Upgrade to Premium",
        cta_path: nil,
        highlighted: true
      }
    ]
  end

  def checkout
    if Rails.env.development? || Rails.env.test?
      current_user.update!(role: :premium)
      redirect_to profile_path, notice: "Subscription activated successfully (Simulation)!"
      return
    end

    # Use Paystack API to initialize payment
    begin
      paystack_response = PaystackService.initialize_payment(
        email: current_user.email,
        amount: 2500 * 100, # Amount in kobo (smallest unit)
        reference: "NORA-#{current_user.id}-#{Time.current.to_i}",
        metadata: {
          user_id: current_user.id,
          plan: "premium"
        }
      )

      Rails.logger.info("Paystack Response: #{paystack_response.inspect}")

      if paystack_response["status"].present?
        redirect_to paystack_response["data"]["authorization_url"], allow_other_host: true
      else
        error_msg = paystack_response["message"] || "Payment initialization failed"
        Rails.logger.error("Paystack Error: #{error_msg}")
        redirect_to pricing_path, alert: "Unable to initiate payment: #{error_msg}"
      end
    rescue => e
      Rails.logger.error("Paystack Exception: #{e.message}\n#{e.backtrace.join("\n")}")
      redirect_to pricing_path, alert: "Payment error: #{e.message}"
    end
  end
end
