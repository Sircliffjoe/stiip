class PricingController < ApplicationController
  before_action :authenticate_user!, only: [:checkout]

  def index
    @plans = [
      {
        key: :free,
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
        key: :premium,
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
      },
      {
        key: :business_api,
        name: "Business/API",
        price: 25000,
        period: "month",
        description: "Commercial data access for apps, dashboards, teams, and fintech products",
        features: [
          "Everything in Premium",
          "Commercial API access",
          "100,000 API requests/month",
          "120 requests/minute",
          "API key management",
          "Commercial redistribution license",
          "Priority integration support"
        ],
        cta: "Start Business/API",
        cta_path: nil,
        highlighted: false
      }
    ]
  end

  def checkout
    plan = params[:plan].presence_in(%w[premium business_api]) || "premium"
    amount = plan == "business_api" ? 25_000 : 2_500

    if Rails.env.development? || Rails.env.test?
      Subscriptions::Activate.new(user: current_user, plan: plan, payment_reference: "SIM-#{SecureRandom.hex(8)}").call
      redirect_to profile_path, notice: "#{plan.titleize} subscription activated successfully (Simulation)!"
      return
    end

    # Use Paystack API to initialize payment
    begin
      paystack_response = PaystackService.initialize_payment(
        email: current_user.email,
        amount: amount * 100, # Amount in kobo (smallest unit)
        reference: "NORA-#{current_user.id}-#{Time.current.to_i}",
        metadata: {
          user_id: current_user.id,
          plan: plan
        },
        callback_url: callback_pricing_index_url
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

  def callback
    reference = params[:reference].to_s
    redirect_to pricing_path, alert: "Missing payment reference." and return if reference.blank?

    verify_response = PaystackService.verify_payment(reference)
    data = verify_response["data"] || {}

    unless verify_response["status"] && data["status"] == "success"
      redirect_to pricing_path, alert: verify_response["message"].presence || "Payment could not be verified."
      return
    end

    user = User.find(data.dig("metadata", "user_id"))
    plan = data.dig("metadata", "plan")

    Subscriptions::Activate.new(user: user, plan: plan, payment_reference: reference).call
    redirect_to profile_path, notice: "#{plan.to_s.titleize} subscription activated successfully!"
  rescue ActiveRecord::RecordNotFound
    redirect_to pricing_path, alert: "Payment verified, but the matching user could not be found. Please contact support."
  rescue StandardError => e
    Rails.logger.error("Payment callback failed: #{e.class} - #{e.message}")
    redirect_to pricing_path, alert: "Payment verification failed. Please contact support if you were debited."
  end
end
