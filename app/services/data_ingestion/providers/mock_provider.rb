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
              title: "Market Update #{i+1}",
              content: "Detailed mock content for the news update. This demonstrates what an article would look like.",
              source: "MockFinancialNews",
              url: "https://example.com/news/#{i}",
              published_at: Time.current - rand(1..48).hours,
              related_tickers: [Company.all.sample&.ticker_symbol].compact
            }
          end
        end
      end
    end
  end
end
