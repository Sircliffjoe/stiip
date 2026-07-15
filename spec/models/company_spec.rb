require "rails_helper"

RSpec.describe Company, type: :model do
  subject(:company) do
    sector = Sector.create!(name: "Financial Services")
    described_class.new(name: "GTCO", ticker_symbol: "GTCO", sector: sector)
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:ticker_symbol) }
    it { should validate_uniqueness_of(:ticker_symbol) }
  end

  describe 'associations' do
    it { should belong_to(:sector) }
    it { should have_many(:stock_prices).dependent(:destroy) }
  end

  describe '#pe_ratio_explanation' do
    it 'returns undervalued message for low PE' do
      company = Company.new(pe_ratio: 8)
      expect(company.pe_ratio_explanation).to include('undervalued')
    end

    it 'returns high growth message for high PE' do
      company = Company.new(pe_ratio: 30)
      expect(company.pe_ratio_explanation).to include('priced high')
    end
  end

  describe "#logo_source" do
    it "uses an explicit API logo URL first" do
      company.logo_url = "https://cdn.example.com/gtco.png"
      company.website = "https://gtbank.com"

      expect(company.logo_source).to eq("https://cdn.example.com/gtco.png")
    end

    it "falls back to a real website favicon when a logo URL is not stored" do
      company.website = "gtbank.com"

      expect(company.logo_source).to include("www.google.com/s2/favicons")
      expect(company.logo_source).to include("domain=gtbank.com")
    end
  end
end
