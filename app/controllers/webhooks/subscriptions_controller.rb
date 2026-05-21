module Webhooks
  class SubscriptionsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      # Paystack/Flutterwave webhook handling
      event = params[:event]
      data = params[:data]

      case event
      when 'charge.success'
        Subscriptions::ProcessPayment.new(data).call
      when 'subscription.disable'
        Subscriptions::Cancel.new(data).call
      end

      head :ok
    rescue StandardError => e
      Rails.logger.error("Webhook processing failed: #{e.message}")
      head :unprocessable_entity
    end
  end
end
