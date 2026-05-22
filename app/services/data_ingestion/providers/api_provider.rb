module DataIngestion
  module Providers
    class ApiProvider < BaseProvider
      # Generic REST API provider for stock data
      # Supports common financial APIs like Alpha Vantage, Finnhub, etc.
      
      def initialize(api_key: ENV["STOCK_API_KEY"], base_url: ENV["STOCK_API_BASE_URL"])
        @api_key = api_key
        @base_url = base_url || "https://api.example.com"
        raise ArgumentError, "API key required for ApiProvider" if api_key.blank?
      end

      def fetch_end_of_day_prices(date: Date.current)
        handle_request do
          companies = Company.all
          prices = []
          
          companies.each do |company|
            data = fetch_single_ticker_price(company.ticker_symbol, date)
            prices << data if data
          end
          
          prices
        end
      end

      def fetch_dividends(start_date:, end_date:)
        handle_request do
          companies = Company.all
          dividends = []
          
          companies.each do |company|
            data = fetch_single_ticker_dividends(company.ticker_symbol, start_date, end_date)
            dividends.concat(data) if data.is_a?(Array)
          end
          
          dividends
        end
      end

      def fetch_news(limit: 20)
        handle_request do
          url = "#{@base_url}/news"
          response = make_request(url, q: "Nigerian stocks", limit: limit)
          
          return [] unless response&.success?
          
          articles = response.parsed_response["articles"] || []
          articles.map { |article| normalize_api_news(article) }
        end
      end

      private

      def fetch_single_ticker_price(ticker, date)
        url = "#{@base_url}/quote/#{ticker}"
        
        response = make_request(url, date: date.to_s)
        return nil unless response&.success?
        
        data = response.parsed_response
        {
          ticker_symbol: ticker,
          date: date,
          open: data["o"]&.to_f,
          high: data["h"]&.to_f,
          low: data["l"]&.to_f,
          close: data["c"]&.to_f,
          volume: data["v"]&.to_i
        }
      rescue StandardError => e
        Rails.logger.error("[ApiProvider] Error fetching #{ticker}: #{e.message}")
        nil
      end

      def fetch_single_ticker_dividends(ticker, start_date, end_date)
        url = "#{@base_url}/dividends/#{ticker}"
        
        response = make_request(url, from: start_date.to_s, to: end_date.to_s)
        return [] unless response&.success?
        
        dividends = response.parsed_response["results"] || []
        dividends.map do |div|
          {
            ticker_symbol: ticker,
            amount: div["amount"]&.to_f,
            qualification_date: parse_dividend_date(div["recordDate"]),
            payment_date: parse_dividend_date(div["payDate"]),
            year: parse_dividend_date(div["exDate"])&.year
          }
        end
      rescue StandardError => e
        Rails.logger.error("[ApiProvider] Error fetching dividends for #{ticker}: #{e.message}")
        []
      end

      def normalize_api_news(article)
        {
          title: article["headline"] || article["title"],
          content: article["summary"] || article["description"],
          source: article["source"] || "API Provider",
          url: article["url"],
          published_at: parse_news_datetime(article["datetime"] || article["publishedAt"]),
          related_tickers: parse_related_tickers(article["related"] || article["tickers"])
        }
      end

      def parse_dividend_date(value)
        return nil if value.blank?
        case value
        when String
          Date.parse(value)
        when Integer
          Time.at(value).to_date
        else
          value
        end
      rescue StandardError
        nil
      end

      def parse_news_datetime(value)
        return Time.current if value.blank?
        case value
        when String
          Time.parse(value)
        when Integer
          Time.at(value)
        else
          Time.current
        end
      rescue StandardError
        Time.current
      end

      def parse_related_tickers(value)
        return [] if value.blank?
        
        case value
        when Array
          value.map { |t| t.is_a?(Hash) ? t["symbol"] : t }.compact.map(&:upcase)
        when String
          value.split(",").map(&:strip).map(&:upcase).compact
        else
          []
        end
      end

      def make_request(url, params = {})
        begin
          response = HTTParty.get(
            url,
            query: params.merge(apikey: @api_key),
            timeout: 10,
            format: :json
          )
          
          if response.success?
            response
          else
            raise APIError, "HTTP #{response.code}: #{response.message}"
          end
        rescue StandardError => e
          Rails.logger.error("[ApiProvider] Request failed: #{e.message}")
          nil
        end
      end
    end
  end
end
