require "rails_helper"

RSpec.describe "User registration", type: :request do
  before { ActionMailer::Base.deliveries.clear }

  it "creates a free user and sends a confirmation email" do
    expect {
      post user_registration_path, params: {
        user: {
          first_name: "Ada",
          last_name: "Investor",
          email: "ada.investor@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    }.to change(User, :count).by(1)
      .and change(ActionMailer::Base.deliveries, :count).by(1)

    user = User.find_by!(email: "ada.investor@example.com")

    expect(user).not_to be_confirmed
    expect(user.subscription).to be_active
    expect(user.subscription).to be_free
    expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
  end
end
