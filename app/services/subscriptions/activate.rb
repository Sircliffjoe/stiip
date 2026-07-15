module Subscriptions
  class Activate
    VALID_PLANS = %w[premium business_api].freeze

    def initialize(user:, plan:, payment_reference: nil, starts_at: Time.current, expires_at: 1.month.from_now)
      @user = user
      @plan = plan.to_s.presence_in(VALID_PLANS) || "premium"
      @payment_reference = payment_reference
      @starts_at = starts_at
      @expires_at = expires_at
    end

    def call
      existing_subscription = @user.subscription
      return existing_subscription if already_activated?(existing_subscription)

      subscription = nil

      ActiveRecord::Base.transaction do
        subscription = @user.subscription || @user.build_subscription
        subscription.update!(
          status: :active,
          plan: @plan,
          payment_reference: @payment_reference || subscription.payment_reference,
          starts_at: @starts_at,
          expires_at: @expires_at,
          renewal_reminded_at: nil
        )

        @user.update!(role: @plan) unless @user.admin_role? || @user.analyst_role?

        Notification.create!(
          user: @user,
          title: "Welcome to #{subscription.plan.titleize}!",
          body: "Your payment was successful. Your #{subscription.plan.titleize} access is now active until #{subscription.expires_at.strftime('%B %d, %Y')}.",
          notification_type: "success"
        )
      end

      SubscriptionMailer.activated(subscription).deliver_later
      subscription
    end

    private

    def already_activated?(subscription)
      return false unless subscription&.active?
      return false if @payment_reference.blank?

      subscription.payment_reference == @payment_reference
    end
  end
end
