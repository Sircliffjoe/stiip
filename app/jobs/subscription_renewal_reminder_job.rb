class SubscriptionRenewalReminderJob < ApplicationJob
  queue_as :default

  def perform
    Subscription
      .active
      .where(plan: [:premium, :business_api])
      .where(renewal_reminded_at: nil)
      .where(expires_at: Time.current..1.month.from_now.end_of_day)
      .includes(:user)
      .find_each do |subscription|
        SubscriptionMailer.renewal_reminder(subscription).deliver_now
        subscription.update!(renewal_reminded_at: Time.current)

        Notification.create!(
          user: subscription.user,
          title: "Subscription renewal reminder",
          body: "Your #{subscription.plan.titleize} subscription renews on #{subscription.expires_at.strftime('%B %d, %Y')}.",
          notification_type: "info"
        )
      end
  end
end
