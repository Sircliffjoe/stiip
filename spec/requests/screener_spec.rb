require 'rails_helper'

RSpec.describe "Screener", type: :request do
  let(:sector) { Sector.create!(name: "Technology") }
  let!(:company_ng) do
    Company.create!(
      name: "Zenith Bank",
      ticker_symbol: "ZENITH",
      sector: sector,
      country: "NG",
      current_price: 35.50,
      ytd_return: 12.50,
      dividend_yield: 8.5,
      revenue: 500_000_000,
      net_profit: 150_000_000,
      signal: :buy
    )
  end
  let!(:company_us) do
    Company.create!(
      name: "Apple Inc.",
      ticker_symbol: "AAPL",
      sector: sector,
      country: "US",
      current_price: 180.00,
      ytd_return: -2.30,
      dividend_yield: 0.5,
      revenue: 380_000_000_000,
      net_profit: 97_000_000_000,
      signal: :hold
    )
  end

  describe "GET /screener" do
    let(:premium_user) { User.create!(email: "premium-screener@example.com", password: "password", first_name: "Premium", last_name: "User", confirmed_at: Time.current, role: :premium) }

    before do
      sign_in premium_user
    end

    it "returns http success for premium users" do
      get "/screener"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Zenith Bank")
      expect(response.body).to include("Apple Inc.")
    end

    it "shows a locked prompt to guests" do
      sign_out premium_user
      get "/screener"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Log in to access the Smart Screener")
      expect(response.body).not_to include("Zenith Bank")
    end

    it "filters by market" do
      get "/screener", params: { market: "ngx" }
      expect(response.body).to include("Zenith Bank")
      expect(response.body).not_to include("Apple Inc.")
    end

    it "filters by signal" do
      get "/screener", params: { signal: "buy" }
      expect(response.body).to include("Zenith Bank")
      expect(response.body).not_to include("Apple Inc.")
    end

    it "filters by dividend status" do
      get "/screener", params: { dividend_status: "yielding" }
      expect(response.body).to include("Zenith Bank")
    end

    it "filters by search query" do
      get "/screener", params: { search: "AAPL" }
      expect(response.body).to include("Apple Inc.")
      expect(response.body).not_to include("Zenith Bank")
    end
  end
end
