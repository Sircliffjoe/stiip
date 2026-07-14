require "rails_helper"

RSpec.describe "Market", type: :request do
  let!(:sector) { Sector.create!(name: "Financial Services") }
  let!(:gainer) do
    Company.create!(
      name: "Guaranty Trust Holding Company",
      ticker_symbol: "GTCO",
      sector: sector,
      current_price: 50.00,
      opening_price: 45.00,
      market_cap: 1_000_000_000_000,
      shares_outstanding: 20_000_000_000
    )
  end
  let!(:laggard) do
    Company.create!(
      name: "United Bank for Africa",
      ticker_symbol: "UBA",
      sector: sector,
      current_price: 24.00,
      opening_price: 25.00,
      market_cap: 800_000_000_000,
      shares_outstanding: 30_000_000_000
    )
  end
  let!(:article) do
    NewsArticle.create!(
      title: "GTCO Posts Record Profit",
      slug: "gtco-posts-record-profit",
      summary: "Market update",
      category: "Earnings",
      published_at: 1.hour.ago
    )
  end

  before do
    StockPrice.create!(
      company: gainer,
      date: Date.current,
      open: 45.00,
      close: 50.00,
      volume: 2_500_000,
      change_percent: 11.11
    )
    StockPrice.create!(
      company: laggard,
      date: Date.current,
      open: 25.00,
      close: 24.00,
      volume: 1_000_000,
      change_percent: -4.00
    )
  end

  it "renders market content from persisted data with links to show pages" do
    get market_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("GTCO")
    expect(response.body).to include("Guaranty Trust Holding Company")
    expect(response.body).to include(company_path("GTCO"))
    expect(response.body).to include("GTCO Posts Record Profit")
    expect(response.body).to include(news_article_path(article))
    expect(response.body).not_to include("GTCO Releases Q3 2026 Financial Results")
  end

  it "allows top gainer and market news show pages to be viewed" do
    get company_path("GTCO")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Guaranty Trust Holding Company")

    get news_article_path(article)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("GTCO Posts Record Profit")
  end
end
