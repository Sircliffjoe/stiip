require "rails_helper"

RSpec.describe Dividends::Analytics, type: :service do
  it "summarizes yield, growth, and consistency from historical dividends" do
    sector = Sector.create!(name: "Financial Services")
    company = Company.create!(name: "GTCO PLC", ticker_symbol: "GTCO", sector: sector, current_price: 100)
    other_company = Company.create!(name: "UBA PLC", ticker_symbol: "UBA", sector: sector, current_price: 50)

    Dividend.create!(company: company, amount: 2, year: 2024, qualification_date: Date.new(2024, 5, 1), payment_date: Date.new(2024, 5, 10))
    Dividend.create!(company: company, amount: 4, year: 2025, qualification_date: Date.new(2025, 5, 1), payment_date: Date.new(2025, 5, 10))
    Dividend.create!(company: other_company, amount: 1, year: 2025, qualification_date: Date.new(2025, 6, 1), payment_date: Date.new(2025, 6, 10))

    summary = described_class.new(Dividend.includes(:company).to_a).summary

    expect(summary[:companies_count]).to eq(2)
    expect(summary[:records_count]).to eq(3)
    expect(summary[:total_declared]).to eq(7)
    expect(summary[:top_yields].first[:company]).to eq(company)
    expect(summary[:top_yields].first[:latest_yield_percent]).to eq(4.0)
    expect(summary[:strongest_growth].first[:growth_percent]).to eq(100.0)
    expect(summary[:most_consistent].first[:years_paid]).to eq(2)
  end
end
