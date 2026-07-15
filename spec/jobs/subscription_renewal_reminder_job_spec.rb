require "rails_helper"

RSpec.describe SubscriptionRenewalReminderJob, type: :job do
  before { ActionMailer::Base.deliveries.clear }

  it "emails paid users expiring within one month once" do
    user = User.create!(
      email: "renewal@example.com",
      password: "password123",
      first_name: "Renewal",
      last_name: "User",
      confirmed_at: Time.current,
      role: :premium
    )
    subscription = user.subscription
    subscription.update!(
      plan: :premium,
      status: :active,
      starts_at: 1.month.ago,
      expires_at: 29.days.from_now,
      renewal_reminded_at: nil
    )

    expect {
      described_class.perform_now
    }.to change(ActionMailer::Base.deliveries, :count).by(1)
      .and change(Notification, :count).by(1)

    expect(subscription.reload.renewal_reminded_at).to be_present
    expect(ActionMailer::Base.deliveries.last.to).to include(user.email)

    expect {
      described_class.perform_now
    }.not_to change(ActionMailer::Base.deliveries, :count)
  end

  it "does not email free subscriptions" do
    user = User.create!(
      email: "free-renewal@example.com",
      password: "password123",
      first_name: "Free",
      last_name: "User",
      confirmed_at: Time.current
    )
    user.subscription.update!(
      plan: :free,
      status: :active,
      expires_at: 29.days.from_now,
      renewal_reminded_at: nil
    )

    expect {
      described_class.perform_now
    }.not_to change(ActionMailer::Base.deliveries, :count)
  end
end
