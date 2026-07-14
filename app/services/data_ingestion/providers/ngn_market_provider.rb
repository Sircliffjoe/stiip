module DataIngestion
  module Providers
    class NgnMarketProvider < BaseProvider
      require "json"
      require "net/http"
      require "uri"

      BASE_URL = "https://api.ngnmarket.com/v1".freeze
      TIMEOUT = 10.freeze
      RETRIES = 3.freeze
      PAGE_SIZE = 100.freeze

      def initialize(api_key: ENV["NGN_MARKET_KEY"], base_url: BASE_URL)
        @api_key = api_key
        @base_url = base_url
        raise ArgumentError, "NGN_MARKET_KEY is required for NgnMarketProvider" if @api_key.blank?
      end

      def fetch_end_of_day_prices(date: Date.current)
        handle_request do
          Rails.logger.info("[NgnMarketProvider] Fetching market snapshots for #{date}")
          fetch_company_snapshots.map { |company| normalize_company(company, date) }.compact
        end
      end

      def fetch_stock_price(symbol, date: Date.current)
        handle_request do
          normalize_company(fetch_company_from_snapshot(symbol), date)
        end
      end

      def fetch_companies
        handle_request do
          fetch_company_snapshots.map { |company| normalize_company_profile(company) }.compact
        end
      end

      def fetch_dividends(start_date:, end_date:)
        handle_request do
          Rails.logger.info("[NgnMarketProvider] Dividend endpoint unavailable for current plan")
          []
        end
      end

      def fetch_news(limit: 20)
        handle_request do
          Rails.logger.info("[NgnMarketProvider] News endpoint unavailable for current plan")
          []
        end
      end

      private

      def fetch_company_snapshots
        companies = []
        page = 1

        loop do
          response = get_json("/companies", page: page, limit: PAGE_SIZE)
          payload = response.dig("data", "data") || response["data"] || []
          companies.concat(Array(payload))

          pagination = response.dig("data", "pagination") || response["pagination"] || {}
          pages = pagination["pages"].to_i
          break if pages.zero? || page >= pages

          page += 1
        end

        companies
      end

      def fetch_company_from_snapshot(symbol)
        fetch_company_snapshots.find { |company| value_for(company, "symbol").to_s.casecmp?(symbol.to_s) }
      end

      def normalize_company_profile(company)
        return nil unless company.is_a?(Hash)

        {
          ticker_symbol: value_for(company, "symbol", "ticker", "ticker_symbol"),
          name: value_for(company, "name"),
          sector: value_for(company, "sector"),
          website: normalize_website(value_for(company, "website")),
          shares_outstanding: value_for(company, "shares_outstanding"),
          market_cap: value_for(company, "market_cap"),
          current_price: value_for(company, "price", "current_price", "close"),
          opening_price: value_for(company, "prev_close", "previous_close"),
          closing_price: value_for(company, "price", "current_price", "close"),
          high_52_week: value_for(company, "high_52wk", "high_52_week"),
          low_52_week: value_for(company, "low_52wk", "low_52_week"),
          source: "NGN Market",
          source_time: parse_time(value_for(company, "last_updated", "trade_date", "date")),
          listed: true
        }
      end

      def normalize_company(company, date)
        return nil unless company.is_a?(Hash)

        close = value_for(company, "price", "current_price", "close")
        return nil if close.blank?

        previous_close = value_for(company, "prev_close", "previous_close")
        change_percent = value_for(company, "price_change_percent", "change_percent")
        open = previous_close || price_from_change(close, change_percent) || close

        {
          ticker_symbol: value_for(company, "symbol", "ticker", "ticker_symbol"),
          date: parse_date(value_for(company, "last_updated", "trade_date", "date")) || date,
          open: open,
          high: value_for(company, "day_high", "high") || [open, close].compact.map(&:to_d).max,
          low: value_for(company, "day_low", "low") || [open, close].compact.map(&:to_d).min,
          close: close,
          volume: value_for(company, "volume"),
          change_percent: change_percent,
          market_cap: value_for(company, "market_cap"),
          shares_outstanding: value_for(company, "shares_outstanding"),
          high_52_week: value_for(company, "high_52wk", "high_52_week"),
          low_52_week: value_for(company, "low_52wk", "low_52_week"),
          source: "NGN Market",
          source_time: parse_time(value_for(company, "last_updated", "trade_date", "date"))
        }
      end

      def get_json(path, params = {})
        attempt = 0

        loop do
          attempt += 1

          begin
            uri = URI.join("#{@base_url}/", path.to_s.delete_prefix("/"))
            uri.query = URI.encode_www_form(params) if params.any?

            request = Net::HTTP::Get.new(uri)
            request["Authorization"] = "Bearer #{@api_key}"
            request["Accept"] = "application/json"

            response = nil
            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: TIMEOUT, open_timeout: TIMEOUT) do |http|
              response = http.request(request)
            end

            return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

            message = JSON.parse(response.body).dig("error", "message") rescue response.message
            raise APIError, "HTTP #{response.code}: #{message}"
          rescue StandardError => e
            if attempt <= RETRIES
              wait_time = 2**attempt
              Rails.logger.warn("[NgnMarketProvider] Attempt #{attempt} failed. Retrying in #{wait_time}s: #{e.message}")
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
      end

      def parse_time(value)
        return nil if value.blank?

        value.is_a?(Time) ? value : Time.parse(value.to_s)
      rescue StandardError
        nil
      end

      def normalize_website(value)
        return nil if value.blank?

        website = value.to_s.strip
        website.match?(%r{\Ahttps?://}) ? website : "https://#{website}"
      end
    end
  end
end
