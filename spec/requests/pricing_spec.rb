require 'rails_helper'

RSpec.describe "Pricing & Subscriptions Flow", type: :request do
  let(:user) { User.create!(email: "investor@example.com", password: "password", first_name: "Investor", last_name: "Test", confirmed_at: Time.current) }

  before do
    sign_in user
  end

  describe "GET /pricing" do
    it "renders the pricing page" do
      get pricing_index_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Simple, transparent pricing")
    end
  end

  describe "POST /pricing/checkout" do
    context "in development/test simulator mode" do
      it "upgrades the user to premium and redirects to profile" do
        post checkout_pricing_index_path(plan: "premium")
        expect(response).to redirect_to(profile_path)
        expect(user.reload.role).to eq("premium")
        expect(flash[:notice]).to eq("Premium subscription activated successfully (Simulation)!")
      end
    end
  end

  describe "POST /webhooks/subscriptions" do
    let(:payload) do
      {
        event: "subscription.disable",
        data: {
          customer: {
            email: user.email
          },
          plan: {
            code: "premium"
          }
        }
      }
    end

    it "handles webhook events and cancels subscription" do
      user.update!(role: :premium)
      Subscription.create!(user: user, plan: :premium, status: :active)

      post webhooks_subscriptions_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(user.reload.role).to eq("free")
    end
  end
end
