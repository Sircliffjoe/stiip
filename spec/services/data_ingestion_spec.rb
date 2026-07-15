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

  describe "#sync_companies" do
    it "creates sectors and companies from provider snapshots" do
      provider = Class.new(DataIngestion::Providers::BaseProvider) do
        def fetch_companies
          [
            {
              ticker_symbol: "MTNN",
              name: "MTN NIGERIA COMMUNICATIONS PLC",
              sector: "ICT",
              current_price: "820.00",
              shares_outstanding: "20995560103",
              market_cap: "17216359284460.00",
              listed: true
            }
          ]
        end
      end.new
      coordinator = described_class.new(provider: provider)

      result = coordinator.sync_companies

      expect(result[:success]).to be true
      expect(Company.find_by!(ticker_symbol: "MTNN").sector.name).to eq("ICT")
      expect(Company.find_by!(ticker_symbol: "MTNN").current_price).to eq(820)
    end

    it "uses sector slugs as identity when API casing changes" do
      Sector.create!(name: "ICT")
      provider = Class.new(DataIngestion::Providers::BaseProvider) do
        def fetch_companies
          [
            { ticker_symbol: "AIRTELAFRI", name: "AIRTEL AFRICA PLC", sector: "Ict", current_price: "2500.00" }
          ]
        end
      end.new
      coordinator = described_class.new(provider: provider)

      result = coordinator.sync_companies

      expect(result[:success]).to be true
      expect(Sector.where(slug: "ict").count).to eq(1)
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

    it "persists multiple same-year dividends for the same company and type idempotently" do
      provider = Class.new(DataIngestion::Providers::BaseProvider) do
        def fetch_dividends(start_date:, end_date:)
          [
            {
              ticker_symbol: "GTCO",
              amount: 2.0,
              qualification_date: Date.new(2026, 3, 24),
              payment_date: Date.new(2026, 4, 15),
              year: 2026,
              interim: false,
              currency: "NGN"
            },
            {
              ticker_symbol: "GTCO",
              amount: 3.0,
              qualification_date: Date.new(2026, 5, 24),
              payment_date: Date.new(2026, 6, 15),
              year: 2026,
              interim: false,
              currency: "NGN"
            }
          ]
        end
      end.new
      coordinator = described_class.new(provider: provider)

      expect {
        coordinator.sync_dividends
      }.to change { Dividend.where(company: company, year: 2026, interim: false).count }.by(2)

      expect {
        coordinator.sync_dividends
      }.not_to change { Dividend.where(company: company, year: 2026, interim: false).count }
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
        year: 2026,
        interim: true,
        currency: "ngn"
      }

      result = normalizer.normalize_dividend(data)

      expect(result[:ticker_symbol]).to eq("GTCO")
      expect(result[:amount]).to eq(2.5)
      expect(result[:interim]).to be true
      expect(result[:currency]).to eq("NGN")
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

RSpec.describe DataIngestion::Providers::NgxProvider, type: :service do
  let(:provider) { described_class.new(api_key: "test-key") }

  describe "#fetch_end_of_day_prices" do
    it "normalizes NGX Pulse stock snapshots" do
      allow(provider).to receive(:get_json).with("/api/ngxdata/stocks").and_return([
        {
          "symbol" => "GTCO",
          "current_price" => 72.5,
          "change_percent" => 1.25,
          "volume" => 1_200_000,
          "market_cap" => 2_100_000_000_000,
          "shares_outstanding" => 29_400_000_000,
          "pe_ratio" => 5.8
        }
      ])

      result = provider.fetch_end_of_day_prices(date: Date.current)

      expect(result.first).to include(
        ticker_symbol: "GTCO",
        close: 72.5,
        volume: 1_200_000,
        change_percent: 1.25,
        market_cap: 2_100_000_000_000,
        shares_outstanding: 29_400_000_000,
        pe_ratio: 5.8
      )
    end

    it "handles the live NGX Pulse stocks wrapper" do
      allow(provider).to receive(:get_json).with("/api/ngxdata/stocks").and_return(
        "stocks" => [
          { "symbol" => "GTCO", "current_price" => 72.5, "volume" => 1_200_000 }
        ]
      )

      result = provider.fetch_end_of_day_prices(date: Date.current)

      expect(result.first[:ticker_symbol]).to eq("GTCO")
      expect(result.first[:close]).to eq(72.5)
    end
  end

  describe "#fetch_stock_price" do
    it "fetches a single ticker quote" do
      allow(provider).to receive(:get_json).with("/api/ngxdata/prices/GTCO").and_return(
        "symbol" => "GTCO",
        "prices" => [
          { "trade_date" => "2026-05-20", "open_price" => 71.0, "close_price" => 71.5, "volume" => 800_000 },
          { "trade_date" => "2026-05-21", "open_price" => 72.0, "close_price" => 72.5, "volume" => 1_200_000 }
        ]
      )

      result = provider.fetch_stock_price("gtco", date: Date.current)

      expect(result[:ticker_symbol]).to eq("GTCO")
      expect(result[:close]).to eq(72.5)
      expect(result[:date]).to eq(Date.new(2026, 5, 21))
    end
  end
end

RSpec.describe DataIngestion::Providers::NgnMarketProvider, type: :service do
  let(:provider) { described_class.new(api_key: "test-key") }

  describe "#fetch_end_of_day_prices" do
    it "normalizes NGN Market company snapshots" do
      allow(provider).to receive(:get_json).with("/companies", page: 1, limit: 100).and_return(
        "data" => {
          "data" => [
            {
              "symbol" => "GTCO",
              "price" => "94.0000",
              "prev_close" => "93.0000",
              "volume" => "9751869",
              "market_cap" => "2766000000000.00",
              "shares_outstanding" => "29400000000",
              "price_change_percent" => "1.0753",
              "high_52wk" => "94.0000",
              "low_52wk" => "39.5000",
              "last_updated" => "2026-05-28T15:40:03.000Z"
            }
          ],
          "pagination" => { "page" => 1, "pages" => 1 }
        }
      )

      result = provider.fetch_end_of_day_prices(date: Date.current)

      expect(result.first).to include(
        ticker_symbol: "GTCO",
        close: "94.0000",
        open: "93.0000",
        volume: "9751869",
        market_cap: "2766000000000.00",
        shares_outstanding: "29400000000",
        change_percent: "1.0753",
        high_52_week: "94.0000",
        low_52_week: "39.5000",
        source: "NGN Market"
      )
    end
  end

  describe "#fetch_stock_price" do
    it "finds a ticker from the market snapshot" do
      allow(provider).to receive(:get_json).with("/companies", page: 1, limit: 100).and_return(
        "data" => {
          "data" => [
            { "symbol" => "UBA", "price" => "45.0000", "last_updated" => "2026-05-28T15:40:03.000Z" }
          ],
          "pagination" => { "page" => 1, "pages" => 1 }
        }
      )

      result = provider.fetch_stock_price("uba", date: Date.current)

      expect(result[:ticker_symbol]).to eq("UBA")
      expect(result[:close]).to eq("45.0000")
    end
  end
end

RSpec.describe DataIngestion::Providers::CompositeMarketProvider, type: :service do
  describe "#fetch_end_of_day_prices" do
    it "keeps the freshest row per ticker across providers" do
      older_provider = instance_double(
        DataIngestion::Providers::BaseProvider,
        fetch_end_of_day_prices: [
          { ticker_symbol: "GTCO", close: 90, date: Date.new(2026, 5, 27), source_time: Time.zone.parse("2026-05-27 15:00") }
        ]
      )
      newer_provider = instance_double(
        DataIngestion::Providers::BaseProvider,
        fetch_end_of_day_prices: [
          { ticker_symbol: "GTCO", close: 94, date: Date.new(2026, 5, 28), source_time: Time.zone.parse("2026-05-28 15:00") }
        ]
      )
      provider = described_class.new(providers: [older_provider, newer_provider])

      result = provider.fetch_end_of_day_prices(date: Date.current)

      expect(result.length).to eq(1)
      expect(result.first[:close]).to eq(94)
    end
  end

  describe "#fetch_news" do
    it "uses providers that are available even when other providers are unavailable" do
      provider = described_class.new(providers: [
        Class.new do
          def fetch_news(limit:)
            raise "provider missing credentials"
          end
        end.new,
        Class.new do
          def fetch_news(limit:)
            [{ title: "Live Market News", url: "https://example.com/news" }]
          end
        end.new
      ])

      result = provider.fetch_news(limit: 5)

      expect(result.length).to eq(1)
      expect(result.first[:title]).to eq("Live Market News")
    end
  end

  describe "#fetch_companies" do
    it "merges provider profile fields so logo data is not lost when price providers win" do
      provider = described_class.new(providers: [
        Class.new do
          def fetch_companies
            [
              {
                ticker_symbol: "GTCO",
                name: "GTCO PLC",
                current_price: 40,
                source: "NGN Market",
                source_time: Time.current
              }
            ]
          end
        end.new,
        Class.new do
          def fetch_companies
            [
              {
                ticker_symbol: "GTCO",
                name: "Guaranty Trust Holding Company PLC",
                logo_url: "https://eodhd.com/img/logos/GTCO.png",
                website: "https://www.gtcoplc.com",
                source: "EODHD"
              }
            ]
          end
        end.new
      ])

      result = provider.fetch_companies

      expect(result.first).to include(
        ticker_symbol: "GTCO",
        current_price: 40,
        logo_url: "https://eodhd.com/img/logos/GTCO.png",
        website: "https://www.gtcoplc.com"
      )
    end
  end
end

RSpec.describe DataIngestion::Providers::EodhdProvider, type: :service do
  let(:provider) { described_class.new(api_key: "test-key") }

  describe "#fetch_companies" do
    it "populates listed companies from EODHD exchange symbols and enriches logos from fundamentals" do
      allow(provider).to receive(:company_fundamentals_limit).and_return(5)
      allow(provider).to receive(:get_json).with("/exchange-symbol-list/XNSA").and_return([
        {
          "Code" => "GTCO",
          "Name" => "GTCO PLC",
          "Type" => "Common Stock",
          "Country" => "Nigeria"
        }
      ])
      allow(provider).to receive(:get_json).with(
        "/fundamentals/GTCO.XNSA",
        filter: "General,Highlights"
      ).and_return({
        "General" => {
          "Name" => "Guaranty Trust Holding Company PLC",
          "Sector" => "Financial Services",
          "WebURL" => "https://www.gtcoplc.com",
          "LogoURL" => "https://eodhd.com/img/logos/ngx/GTCO.png",
          "Description" => "A listed Nigerian financial services group.",
          "CountryISO" => "NG"
        },
        "Highlights" => {
          "MarketCapitalization" => 1_000_000_000
        }
      })

      result = provider.fetch_companies

      expect(result.length).to eq(1)
      expect(result.first).to include(
        ticker_symbol: "GTCO",
        name: "Guaranty Trust Holding Company PLC",
        sector: "Financial Services",
        website: "https://www.gtcoplc.com",
        logo_url: "https://eodhd.com/img/logos/ngx/GTCO.png",
        country: "NG",
        source: "EODHD",
        listed: true
      )
    end
  end

  describe "#fetch_dividends" do
    it "normalizes Nigerian dividend history from EODHD" do
      sector = Sector.create!(name: "Financial Services")
      Company.create!(name: "GTCO PLC", ticker_symbol: "GTCO", sector: sector)

      allow(provider).to receive(:get_json).with(
        "/div/GTCO.XNSA",
        from: "2020-01-01",
        to: "2026-12-31"
      ).and_return([
        {
          "date" => "2026-03-24",
          "recordDate" => "2026-03-25",
          "paymentDate" => "2026-04-15",
          "value" => 4.0,
          "unadjustedValue" => 4.0,
          "currency" => "NGN"
        },
        {
          "date" => "2026-09-24",
          "value" => 1.0,
          "currency" => "NGN"
        }
      ])

      result = provider.fetch_dividends(start_date: Date.new(2020, 1, 1), end_date: Date.new(2026, 12, 31))

      expect(result.length).to eq(2)
      expect(result.first).to include(
        ticker_symbol: "GTCO",
        amount: 4.0,
        qualification_date: Date.new(2026, 3, 25),
        payment_date: Date.new(2026, 4, 15),
        year: 2026,
        interim: false,
        currency: "NGN"
      )
      expect(result.second[:interim]).to be true
    end

    it "tries configured exchange code fallbacks until dividends are found" do
      sector = Sector.create!(name: "Financial Services")
      Company.create!(name: "GTCO PLC", ticker_symbol: "GTCO", sector: sector)
      provider = described_class.new(api_key: "test-key", exchange_codes: "BAD,XNSA")

      allow(provider).to receive(:get_json).with(
        "/div/GTCO.BAD",
        from: "2026-01-01",
        to: "2026-12-31"
      ).and_return([])
      allow(provider).to receive(:get_json).with(
        "/div/GTCO.XNSA",
        from: "2026-01-01",
        to: "2026-12-31"
      ).and_return([
        {
          "date" => "2026-03-24",
          "recordDate" => "2026-03-25",
          "paymentDate" => "2026-04-15",
          "value" => 4.0,
          "currency" => "NGN"
        }
      ])

      result = provider.fetch_dividends(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 12, 31))

      expect(result.length).to eq(1)
      expect(result.first[:amount]).to eq(4.0)
    end
  end

  describe "#fetch_news" do
    it "normalizes EODHD financial news" do
      allow(provider).to receive(:news_tags).and_return(["NIGERIA"])
      allow(provider).to receive(:news_symbol_limit).and_return(0)
      allow(provider).to receive(:get_json).with(
        "/news",
        { t: "NIGERIA", limit: 10, offset: 0 }
      ).and_return([
        {
          "date" => "2026-07-15T10:00:00+00:00",
          "title" => "Nigeria inflation cools as equities rally",
          "content" => "Financial markets update for Nigerian investors.",
          "link" => "https://reliable.example/news/nigeria-inflation-equities",
          "symbols" => ["GTCO.XNSA", "UBA.XNSA"]
        }
      ])

      result = provider.fetch_news(limit: 10)

      expect(result.length).to eq(1)
      expect(result.first).to include(
        title: "Nigeria inflation cools as equities rally",
        content: "Financial markets update for Nigerian investors.",
        source: "reliable.example",
        url: "https://reliable.example/news/nigeria-inflation-equities",
        related_tickers: ["GTCO", "UBA"]
      )
      expect(result.first[:published_at]).to be_a(Time)
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
