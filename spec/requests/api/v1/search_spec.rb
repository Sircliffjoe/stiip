require 'rails_helper'

RSpec.describe "Api::V1::Searches", type: :request do
  let!(:company) { Company.create!(name: "Guaranty Trust Bank", ticker_symbol: "GTCO", sector: Sector.find_or_create_by!(name: "Banking", slug: "banking")) }
  let(:api_user) { User.create!(email: "api-search@example.com", password: "password", first_name: "API", last_name: "User", confirmed_at: Time.current, role: :business_api) }
  let(:api_key) { api_user.api_keys.create!(name: "RSpec") }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.plain_token}" } }

  before do
    PgSearch::Multisearch.rebuild(Company)
  end

  describe "GET /api/v1/search" do
    it "returns results when query is provided" do
      get api_v1_search_path(query: "Guaranty"), headers: headers
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["companies"].length).to be >= 1
      expect(json["companies"].first["ticker_symbol"]).to eq("GTCO")
    end

    it "returns bad request when query is missing" do
      get api_v1_search_path, headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end
end
