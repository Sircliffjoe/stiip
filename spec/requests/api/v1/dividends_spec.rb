require 'rails_helper'

RSpec.describe "Api::V1::Dividends", type: :request do
  let!(:company) { Company.create!(name: "Test Company", ticker_symbol: "TEST", sector: Sector.find_or_create_by!(name: "Banking", slug: "banking")) }
  let!(:dividend) { Dividend.create!(company: company, amount: 2.50, year: 2026, status: :announced) }
  let(:headers) { { 'Authorization' => 'Bearer test_token' } }

  describe "GET /api/v1/dividends" do
    it "returns all dividends" do
      get api_v1_dividends_path, headers: headers
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["amount"].to_f).to eq(2.50)
    end
  end

  describe "GET /api/v1/companies/:company_ticker_symbol/dividends" do
    it "returns dividends for a specific company" do
      get api_v1_company_prices_path(company_id: company.ticker_symbol), headers: headers
      expect(response).to have_http_status(:success)
    end
  end
end
