require 'fileutils'

directories = [
  'app/services/data_ingestion/providers',
  'app/jobs'
]
directories.each { |dir| FileUtils.mkdir_p(dir) }

files = {}

# Providers Base
files['app/services/data_ingestion/providers/base_provider.rb'] = <<~RUBY
  module DataIngestion
    module Providers
      class BaseProvider
        class APIError < StandardError; end

        def fetch_end_of_day_prices(date: Date.current)
          raise NotImplementedError, "Subclasses must implement fetch_end_of_day_prices"
        end

        def fetch_dividends(start_date:, end_date:)
          raise NotImplementedError, "Subclasses must implement fetch_dividends"
        end

        def fetch_news(limit: 20)
          raise NotImplementedError, "Subclasses must implement fetch_news"
        end
        
        protected
        
        def handle_request
          yield
        rescue StandardError => e
          Rails.logger.error("[\#{self.class.name}] API Error: \#{e.message}")
          raise APIError, e.message
        end
      end
    end
  end
RUBY

# Mock Provider (for development and fallback)
files['app/services/data_ingestion/providers/mock_provider.rb'] = <<~RUBY
  module DataIngestion
    module Providers
      class MockProvider < BaseProvider
        def fetch_end_of_day_prices(date: Date.current)
          handle_request do
            companies = Company.all
            companies.map do |company|
              base_price = company.latest_price || rand(10.0..500.0)
              fluctuation = base_price * rand(-0.05..0.05)
              {
                ticker_symbol: company.ticker_symbol,
                date: date,
                open: (base_price - fluctuation * 0.5).round(2),
                high: (base_price + fluctuation.abs).round(2),
                low: (base_price - fluctuation.abs).round(2),
                close: (base_price + fluctuation).round(2),
                volume: rand(1000..1000000)
              }
            end
          end
        end

        def fetch_dividends(start_date:, end_date:)
          handle_request do
            Company.limit(5).map do |company|
              {
                ticker_symbol: company.ticker_symbol,
                amount: rand(0.5..5.0).round(2),
                qualification_date: start_date + rand(5..15).days,
                payment_date: start_date + rand(20..30).days,
                year: start_date.year
              }
            end
          end
        end

        def fetch_news(limit: 20)
          handle_request do
            limit.times.map do |i|
              {
                title: "Market Update \#{i+1}",
                content: "Detailed mock content for the news update. This demonstrates what an article would look like.",
                source: "MockFinancialNews",
                url: "https://example.com/news/\#{i}",
                published_at: Time.current - rand(1..48).hours,
                related_tickers: [Company.all.sample&.ticker_symbol].compact
              }
            end
          end
        end
      end
    end
  end
RUBY

# FetchStockPrices Service
files['app/services/data_ingestion/fetch_stock_prices.rb'] = <<~RUBY
  module DataIngestion
    class FetchStockPrices
      def initialize(provider: Providers::MockProvider.new)
        @provider = provider
      end

      def call(date: Date.current)
        raw_data = @provider.fetch_end_of_day_prices(date: date)
        
        ActiveRecord::Base.transaction do
          raw_data.each do |data|
            company = Company.find_by(ticker_symbol: data[:ticker_symbol])
            next unless company
            
            StockPrice.find_or_initialize_by(company: company, date: data[:date]).tap do |sp|
              sp.open = data[:open]
              sp.high = data[:high]
              sp.low = data[:low]
              sp.close = data[:close]
              sp.volume = data[:volume]
              sp.save!
            end
            
            company.update!(current_price: data[:close])
          end
        end
      end
    end
  end
RUBY

# FetchDividends Service
files['app/services/data_ingestion/fetch_dividends.rb'] = <<~RUBY
  module DataIngestion
    class FetchDividends
      def initialize(provider: Providers::MockProvider.new)
        @provider = provider
      end

      def call(start_date: Date.current, end_date: 1.month.from_now)
        raw_data = @provider.fetch_dividends(start_date: start_date, end_date: end_date)
        
        ActiveRecord::Base.transaction do
          raw_data.each do |data|
            company = Company.find_by(ticker_symbol: data[:ticker_symbol])
            next unless company
            
            Dividend.find_or_initialize_by(
              company: company, 
              amount: data[:amount], 
              qualification_date: data[:qualification_date]
            ).tap do |div|
              div.payment_date = data[:payment_date]
              div.year = data[:year]
              div.status = :announced
              div.save!
            end
          end
        end
      end
    end
  end
RUBY

# FetchNews Service
files['app/services/data_ingestion/fetch_news.rb'] = <<~RUBY
  module DataIngestion
    class FetchNews
      def initialize(provider: Providers::MockProvider.new)
        @provider = provider
      end

      def call(limit: 20)
        raw_data = @provider.fetch_news(limit: limit)
        
        ActiveRecord::Base.transaction do
          raw_data.each do |data|
            article = NewsArticle.find_or_initialize_by(url: data[:url])
            next if article.persisted? # Skip if we already have it

            article.title = data[:title]
            article.content = data[:content]
            article.source = data[:source]
            article.published_at = data[:published_at]
            article.save!

            # Link to companies if tickers were provided
            data[:related_tickers].each do |ticker|
              company = Company.find_by(ticker_symbol: ticker)
              CompanyNews.create!(company: company, news_article: article) if company
            end
          end
        end
      end
    end
  end
RUBY

# Solid Queue Jobs
files['app/jobs/ingest_market_data_job.rb'] = <<~RUBY
  class IngestMarketDataJob < ApplicationJob
    queue_as :default
    
    # Retry on specific API failures
    retry_on DataIngestion::Providers::BaseProvider::APIError, wait: :exponentially_longer, attempts: 3

    def perform(date_string = Date.current.to_s)
      date = Date.parse(date_string)
      
      # Determine Provider (Can be switched out in production via ENV)
      provider_class = ENV.fetch('MARKET_DATA_PROVIDER', 'MockProvider')
      provider = "DataIngestion::Providers::\#{provider_class}".constantize.new
      
      # Fetch End of Day Prices
      DataIngestion::FetchStockPrices.new(provider: provider).call(date: date)
      
      # Fetch Dividends for the month
      DataIngestion::FetchDividends.new(provider: provider).call
      
      # Log completion
      AuditLog.create!(action: 'market_data_ingestion', details: "Ingested EOD prices and dividends for \#{date}")
    end
  end
RUBY

files['app/jobs/ingest_news_job.rb'] = <<~RUBY
  class IngestNewsJob < ApplicationJob
    queue_as :low_priority
    
    retry_on DataIngestion::Providers::BaseProvider::APIError, wait: 5.minutes, attempts: 3

    def perform
      provider_class = ENV.fetch('NEWS_PROVIDER', 'MockProvider')
      provider = "DataIngestion::Providers::\#{provider_class}".constantize.new
      
      DataIngestion::FetchNews.new(provider: provider).call(limit: 50)
      
      AuditLog.create!(action: 'news_ingestion', details: "Ingested latest market news")
    end
  end
RUBY

files.each do |filename, content|
  File.write(filename, content)
  puts "Created \#{filename}"
end
