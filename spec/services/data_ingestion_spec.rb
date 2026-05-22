require "rails_helper"

RSpec.describe DataIngestion::SyncCoordinator, type: :service do
  let(:coordinator) { described_class.new(provider: :mock) }
  let!(:sector) { Sector.create!(name: "Financial Services") }
  let!(:company) { Company.create!(name: "Guaranty Trust Holding Company", ticker_symbol: "GTCO", sector: sector, current_price: 45.50) }
  let!(:second_company) { Company.create!(name: "United Bank for Africa", ticker_symbol: "UBA", sector: sector, current_price: 26.40) }

  describe "#sync_stock_prices" do
    it "successfully syncs stock prices" do
      result = coordinator.sync_stock_prices(date: Date.current)
      
      expect(result[:success]).to be true
      expect(result[:count]).to be > 0
      expect(result[:date]).to eq(Date.current)
    end

    it "creates StockPrice records in database" do
      expect {
        coordinator.sync_stock_prices
      }.to change { StockPrice.count }
    end

    it "updates company current_price" do
      company = Company.first
      initial_price = company.current_price
      
      coordinator.sync_stock_prices
      company.reload
      
      expect(company.current_price).not_to eq(initial_price)
    end

    it "handles invalid dates gracefully" do
      result = coordinator.sync_stock_prices(date: 1.year.from_now)
      expect(result[:success]).to be false
    end
  end

  describe "#sync_dividends" do
    it "successfully syncs dividends" do
      result = coordinator.sync_dividends
      
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 0
    end

    it "creates Dividend records" do
      expect {
        coordinator.sync_dividends
      }.to change { Dividend.count }
    end
  end

  describe "#sync_news" do
    it "successfully syncs news" do
      result = coordinator.sync_news(limit: 10)
      
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 0
    end
  end

  describe "#sync_all" do
    it "syncs all data types" do
      result = coordinator.sync_all
      
      expect(result[:success]).to be true
      expect(result[:results]).to have_key(:stock_prices)
      expect(result[:results]).to have_key(:dividends)
      expect(result[:results]).to have_key(:news)
    end
  end
end

RSpec.describe DataIngestion::DataNormalizer, type: :service do
  let(:normalizer) { described_class.new }

  describe "#normalize_price" do
    it "normalizes valid price data" do
      data = {
        ticker_symbol: "gtco",
        date: Date.current,
        open: 45.50,
        high: 46.25,
        low: 45.00,
        close: 45.80,
        volume: 2500000
      }

      result = normalizer.normalize_price(data)

      expect(result[:ticker_symbol]).to eq("GTCO")
      expect(result[:open]).to eq(45.50)
      expect(result[:close]).to eq(45.80)
    end

    it "raises ValidationError for invalid ticker" do
      data = {
        ticker_symbol: "",
        date: Date.current,
        close: 45.80
      }

      expect {
        normalizer.normalize_price(data)
      }.to raise_error(DataIngestion::DataNormalizer::ValidationError)
    end

    it "raises ValidationError for inconsistent OHLC" do
      data = {
        ticker_symbol: "GTCO",
        date: Date.current,
        open: 45.00,
        high: 44.00, # High < Low = invalid
        low: 45.00,
        close: 45.80
      }

      expect {
        normalizer.normalize_price(data)
      }.to raise_error(DataIngestion::DataNormalizer::ValidationError, /High.*cannot be less than Low/)
    end

    it "handles missing OHLC fields" do
      data = {
        ticker_symbol: "GTCO",
        date: Date.current,
        close: 45.80,
        volume: 2500000
      }

      result = normalizer.normalize_price(data)

      expect(result[:open]).to eq(45.80) # Auto-filled
      expect(result[:high]).to eq(45.80)
      expect(result[:low]).to eq(45.80)
    end

    it "validates price ranges" do
      data = {
        ticker_symbol: "GTCO",
        date: Date.current,
        close: 2000000 # > 1,000,000 limit
      }

      expect {
        normalizer.normalize_price(data)
      }.to raise_error(DataIngestion::DataNormalizer::ValidationError, /unreasonable/)
    end
  end

  describe "#normalize_dividend" do
    it "normalizes valid dividend data" do
      data = {
        ticker_symbol: "gtco",
        amount: 2.5,
        qualification_date: Date.current,
        payment_date: 30.days.from_now,
        year: 2026
      }

      result = normalizer.normalize_dividend(data)

      expect(result[:ticker_symbol]).to eq("GTCO")
      expect(result[:amount]).to eq(2.5)
    end

    it "validates dividend amount" do
      data = {
        ticker_symbol: "GTCO",
        amount: -1.0
      }

      expect {
        normalizer.normalize_dividend(data)
      }.to raise_error(DataIngestion::DataNormalizer::ValidationError, /non-negative/)
    end
  end

  describe "#normalize_news" do
    it "normalizes valid news data" do
      data = {
        title: "Market Update",
        content: "Detailed content",
        source: "NewsSource",
        url: "https://example.com/news",
        published_at: Time.current,
        related_tickers: ["GTCO", "UBA"]
      }

      result = normalizer.normalize_news(data)

      expect(result[:title]).to eq("Market Update")
      expect(result[:related_tickers]).to eq(["GTCO", "UBA"])
    end

    it "validates title presence" do
      data = {
        title: "",
        content: "Content"
      }

      expect {
        normalizer.normalize_news(data)
      }.to raise_error(DataIngestion::DataNormalizer::ValidationError, /Title is required/)
    end
  end
end

RSpec.describe DataIngestion::Providers::CsvProvider, type: :service do
  let(:temp_file) { Rails.root.join("tmp/test_prices.csv") }

  before do
    File.write(temp_file, <<~CSV)
      ticker_symbol,date,open,high,low,close,volume
      GTCO,2026-05-20,45.50,46.25,45.00,45.80,2500000
      UBA,2026-05-20,21.40,21.85,21.00,21.60,3200000
    CSV
  end

  after { File.delete(temp_file) if File.exist?(temp_file) }

  let(:provider) { DataIngestion::Providers::CsvProvider.new(file_path: temp_file.to_s) }

  describe "#fetch_end_of_day_prices" do
    it "reads CSV file and returns price data" do
      result = provider.fetch_end_of_day_prices

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first[:ticker_symbol]).to eq("GTCO")
      expect(result.first[:close]).to eq(45.80)
    end

    it "raises error for missing file" do
      bad_provider = DataIngestion::Providers::CsvProvider.new(file_path: "/nonexistent/file.csv")
      expect {
        bad_provider.fetch_end_of_day_prices
      }.to raise_error(ArgumentError, /File not found/)
    end
  end
end

RSpec.describe DataImportLog, type: :model do
  describe "validations" do
    it "validates required fields" do
      log = DataImportLog.new
      expect(log).not_to be_valid
      expect(log.errors[:data_type]).to be_present
      expect(log.errors[:provider]).to be_present
    end
  end

  describe "scopes" do
    before do
      DataImportLog.create!(data_type: "Stock Prices", provider: "mock", status: "success", records_imported: 15)
      DataImportLog.create!(data_type: "Dividends", provider: "mock", status: "success", records_imported: 5)
      DataImportLog.create!(data_type: "Stock Prices", provider: "csv", status: "failed", error_message: "Format error")
    end

    it "filters by type" do
      prices = DataImportLog.by_type("Stock Prices")
      expect(prices.count).to eq(2)
    end

    it "filters by provider" do
      mocks = DataImportLog.by_provider("mock")
      expect(mocks.count).to eq(2)
    end

    it "filters successful imports" do
      successful = DataImportLog.successful
      expect(successful.count).to eq(2)
    end

    it "calculates success rate" do
      rate = DataImportLog.success_rate(1.day)
      expect(rate).to be_within(0.01).of(66.67)
    end
  end
end
