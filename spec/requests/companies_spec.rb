require "rails_helper"

RSpec.describe "Companies", type: :request do
  it "renders stored company logos instead of initials when available" do
    sector = Sector.create!(name: "Financial Services")
    Company.create!(
      name: "Guaranty Trust Holding Company",
      ticker_symbol: "GTCO",
      sector: sector,
      logo_url: "https://cdn.example.com/gtco.png"
    )

    get companies_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("https://cdn.example.com/gtco.png")
    expect(response.body).to include("Guaranty Trust Holding Company logo")
  end
end
