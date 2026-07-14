module DataIngestion
  module Providers
    class NgxProvider < BaseProvider
      require "json"
      require "net/http"
      require "uri"
      require "cgi"

      # Provides real-time Nigerian Exchange data through NGX Pulse.
      
      BASE_URL = "https://www.ngxpulse.ng".freeze
      TIMEOUT = 4.freeze
      RETRIES = 0.freeze

      def initialize(api_key: ENV["NGX_PULSE_KEY"], base_url: BASE_URL)
        @api_key = api_key
        @base_url = base_url
        raise ArgumentError, "NGX_PULSE_KEY is required for NgxProvider" if @api_key.blank?
      end

      def fetch_end_of_day_prices(date: Date.current)
        handle_request do
          Rails.logger.info("[NgxProvider] Fetching prices for #{date}")
          fetch_stocks.map { |stock| normalize_stock(stock, date) }.compact
        end
      end

      def fetch_stock_price(symbol, date: Date.current)
        handle_request do
          response = get_json("/api/ngxdata/prices/#{CGI.escape(symbol.to_s.upcase)}")
          normalize_stock(single_price_snapshot(response), date)
        end
      end

      def fetch_companies
        handle_request do
          fetch_stocks.map { |stock| normalize_company_profile(stock) }.compact
        end
      end

      def fetch_dividends(start_date:, end_date:)
        handle_request do
          Rails.logger.info("[NgxProvider] Fetching dividends from #{start_date} to #{end_date}")
          Company.where(listed: true).flat_map do |company|
            fetch_company_dividends(company.ticker_symbol, start_date, end_date)
          end
        end
      end

      def fetch_news(limit: 20)
        handle_request do
          Rails.logger.info("[NgxProvider] Fetching #{limit} news items")
          normalize_news_response(get_json("/api/news")).first(limit)
        end
      end

      private

      def fetch_stocks
        response = get_json("/api/ngxdata/stocks")
        response.is_a?(Hash) ? response.fetch("stocks", response.fetch("data", [])) : response
      end

      def normalize_stock(stock, date)
        return nil unless stock.is_a?(Hash)

        close = value_for(stock, "current_price", "close", "close_price", "price", "last")
        return nil if close.blank?

        previous_close = value_for(stock, "previous_close", "prev_close")
        change_percent = value_for(stock, "change_percent", "change_percentage", "pct_change")
        open = value_for(stock, "open", "open_price", "opening_price") || price_from_change(close, change_percent) || previous_close || close

        {
          ticker_symbol: value_for(stock, "symbol", "ticker", "ticker_symbol"),
          date: parse_date(value_for(stock, "trade_date", "date")) || date,
          open: open,
          high: value_for(stock, "high", "high_price") || [open, close].compact.map(&:to_d).max,
          low: value_for(stock, "low", "low_price") || [open, close].compact.map(&:to_d).min,
          close: close,
          volume: value_for(stock, "volume"),
          change_percent: change_percent,
          market_cap: value_for(stock, "market_cap", "market_capitalisation", "market_capitalization"),
          shares_outstanding: value_for(stock, "shares_outstanding"),
          pe_ratio: value_for(stock, "pe_ratio", "pe")
        }
      end

      def single_price_snapshot(response)
        return response unless response.is_a?(Hash)

        prices = response["prices"] || response[:prices]
        if prices.present?
          latest = Array(prices).max_by { |price| parse_date(value_for(price, "trade_date", "date")) || Date.new(2000, 1, 1) }
          return latest.merge("symbol" => response["symbol"] || response[:symbol]) if latest
        end

        response["data"] || response[:data] || response
      end

      def normalize_company_profile(stock)
        return nil unless stock.is_a?(Hash)

        close = value_for(stock, "current_price", "close", "close_price", "price", "last")

        {
          ticker_symbol: value_for(stock, "symbol", "ticker", "ticker_symbol"),
          name: value_for(stock, "name"),
          sector: value_for(stock, "sector"),
          shares_outstanding: value_for(stock, "shares_outstanding"),
          market_cap: value_for(stock, "market_cap", "market_capitalisation", "market_capitalization"),
          current_price: close,
          opening_price: value_for(stock, "previous_close", "prev_close") || close,
          closing_price: close,
          source: "NGX Pulse",
          source_time: parse_time(value_for(stock, "trade_date", "date")),
          listed: true
        }
      end

      def fetch_company_dividends(symbol, start_date, end_date)
        response = get_json("/api/ngxdata/dividends/#{CGI.escape(symbol)}")
        dividends = response.is_a?(Hash) ? response.fetch("data", response.fetch("dividends", [])) : response

        Array(dividends).filter_map do |dividend|
          normalized = normalize_dividend(symbol, dividend)
          next if normalized[:qualification_date].present? && normalized[:qualification_date] < start_date.to_date
          next if normalized[:qualification_date].present? && normalized[:qualification_date] > end_date.to_date

          normalized
        end
      rescue APIError => e
        Rails.logger.warn("[NgxProvider] Dividend fetch failed for #{symbol}: #{e.message}")
        []
      end

      def normalize_dividend(symbol, dividend)
        {
          ticker_symbol: symbol,
          amount: value_for(dividend, "amount", "cash_amount", "dividend", "dividend_per_share"),
          qualification_date: parse_date(value_for(dividend, "qualification_date", "ex_dividend_date", "ex_date", "record_date")),
          payment_date: parse_date(value_for(dividend, "payment_date", "pay_date")),
          year: parse_date(value_for(dividend, "ex_dividend_date", "ex_date", "record_date", "payment_date"))&.year || Date.current.year,
          interim: value_for(dividend, "type", "dividend_type").to_s.downcase.include?("interim")
        }
      end

      def normalize_news_response(response)
        articles = if response.is_a?(Hash)
                     response["articles"] || response["data"] || response["news"] || []
                   else
                     response
                   end

        Array(articles).filter_map do |article|
          next unless article.is_a?(Hash)
          source = value_for(article, "source", "publisher") || "NGX Pulse"
          url = value_for(article, "url", "link")
          next if source.to_s.casecmp?("Google News") || url.to_s.include?("news.google.com")

          {
            title: value_for(article, "title", "headline"),
            content: value_for(article, "summary", "description", "content", "body"),
            source: source,
            url: url,
            published_at: value_for(article, "published_at", "publishedAt", "date", "created_at") || Time.current,
            related_tickers: parse_related_tickers(value_for(article, "tickers", "symbols", "related_tickers"))
          }
        end
      end

      def get_json(path)
        attempt = 0
        loop do
          attempt += 1
          begin
            uri = URI.join(@base_url, path)
            request = Net::HTTP::Get.new(uri)
            request["X-API-Key"] = @api_key
            request["Content-Type"] = "application/json"
            request["Accept"] = "application/json"

            response = nil
            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: TIMEOUT, open_timeout: TIMEOUT) do |http|
              response = http.request(request)
            end

            if response.is_a?(Net::HTTPRedirection)
              redirected_uri = URI(response["location"])
              redirected_uri = URI.join(uri.to_s, response["location"]) if redirected_uri.relative?
              return get_json(redirected_uri.to_s)
            end

            return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

            message = JSON.parse(response.body)["message"] rescue response.message
            raise APIError, "HTTP #{response.code}: #{message}"
          rescue StandardError => e
            if attempt <= RETRIES
              wait_time = 2 ** attempt
              Rails.logger.warn("[NgxProvider] Attempt #{attempt} failed. Retrying in #{wait_time}s: #{e.message}")
              sleep wait_time
            else
              raise APIError, "Failed after #{RETRIES} retries: #{e.message}"
            end
          end
        end
      end

      def value_for(hash, *keys)
        keys.each do |key|
          value = hash[key] || hash[key.to_sym]
          return value if value.present?
        end
        nil
      end

      def price_from_change(close, change_percent)
        return nil if close.blank? || change_percent.blank?

        close.to_d / (1 + (change_percent.to_d / 100))
      rescue StandardError
        nil
      end

      def parse_date(value)
        parse_time(value)&.to_date
      rescue StandardError
        nil
      end

      def parse_time(value)
        return nil if value.blank?

        value.is_a?(Time) ? value : Time.parse(value.to_s)
      rescue StandardError
        nil
      end

      def parse_related_tickers(value)
        case value
        when Array
          value.map { |ticker| ticker.is_a?(Hash) ? value_for(ticker, "symbol", "ticker") : ticker }.compact
        when String
          value.split(",").map(&:strip)
        else
          []
        end
      end
    end
  end
end
