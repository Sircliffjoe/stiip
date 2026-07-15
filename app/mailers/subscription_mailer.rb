class SubscriptionMailer < ApplicationMailer
  def activated(subscription)
    @subscription = subscription
    @user = subscription.user

    mail(
      to: @user.email,
      subject: "Your NoraCapital #{subscription.plan.titleize} subscription is active"
    )
  end

  def renewal_reminder(subscription)
    @subscription = subscription
    @user = subscription.user

    mail(
      to: @user.email,
      subject: "Your NoraCapital subscription renews soon"
    )
  end
end
