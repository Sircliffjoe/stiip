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
        expect(user.subscription).to be_active
        expect(user.subscription).to be_premium
        expect(user.subscription.expires_at).to be_present
        expect(flash[:notice]).to eq("Premium subscription activated successfully (Simulation)!")
      end
    end
  end

  describe "GET /pricing/callback" do
    it "verifies a successful Paystack payment and activates the subscription" do
      allow(PaystackService).to receive(:verify_payment).with("NORA-REF").and_return(
        "status" => true,
        "data" => {
          "status" => "success",
          "metadata" => {
            "user_id" => user.id,
            "plan" => "business_api"
          }
        }
      )

      get callback_pricing_index_path(reference: "NORA-REF")

      expect(response).to redirect_to(profile_path)
      expect(user.reload).to be_business_api_role
      expect(user.subscription).to be_business_api
      expect(user.subscription.payment_reference).to eq("NORA-REF")
      expect(user.subscription.expires_at).to be_present
    end
  end

  describe "POST /webhooks/paystack" do
    it "activates the paid plan from a verified Paystack webhook" do
      secret = "test_paystack_secret"
      payload = {
        event: "charge.success",
        data: {
          reference: "NORA-WEBHOOK-REF",
          status: "success"
        }
      }.to_json
      signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"), secret, payload)

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("PAYSTACK_SECRET_KEY", "").and_return(secret)
      allow(PaystackService).to receive(:verify_payment).with("NORA-WEBHOOK-REF").and_return(
        "status" => true,
        "data" => {
          "status" => "success",
          "metadata" => {
            "user_id" => user.id,
            "plan" => "premium"
          }
        }
      )

      post webhooks_paystack_path,
        params: payload,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Paystack-Signature" => signature
        }

      expect(response).to have_http_status(:ok)
      expect(user.reload).to be_premium_role
      expect(user.subscription).to be_premium
      expect(user.subscription.payment_reference).to eq("NORA-WEBHOOK-REF")
      expect(user.subscription.expires_at).to be_present
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
