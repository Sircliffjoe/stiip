module DataIngestion
  module Providers
    class EodhdProvider < BaseProvider
      require "json"
      require "net/http"
      require "uri"

      BASE_URL = "https://eodhd.com/api".freeze
      EXCHANGE_CODE = "XNSA".freeze
      TIMEOUT = 8.freeze

      def initialize(api_key: ENV["EODHD_API_KEY"], base_url: BASE_URL, exchange_code: EXCHANGE_CODE)
        @api_key = api_key
        @base_url = base_url
        @exchange_code = exchange_code
        raise ArgumentError, "EODHD_API_KEY is required for EodhdProvider" if @api_key.blank?
      end

      def fetch_end_of_day_prices(date: Date.current)
        []
      end

      def fetch_companies
        []
      end

      def fetch_dividends(start_date:, end_date:)
        handle_request do
          Company.where(listed: true).order(:ticker_symbol).flat_map do |company|
            fetch_company_dividends(company.ticker_symbol, start_date, end_date)
          end
        end
      end

      def fetch_news(limit: 20)
        []
      end

      private

      def fetch_company_dividends(ticker_symbol, start_date, end_date)
        rows = get_json("/div/#{eodhd_symbol(ticker_symbol)}", from: start_date.to_date.to_s, to: end_date.to_date.to_s)

        Array(rows).filter_map do |row|
          normalize_dividend(ticker_symbol, row)
        end
      rescue APIError => e
        Rails.logger.warn("[EodhdProvider] Dividend fetch failed for #{ticker_symbol}: #{e.message}")
        []
      end

      def normalize_dividend(ticker_symbol, row)
        ex_date = parse_date(value_for(row, "date"))
        payment_date = parse_date(value_for(row, "paymentDate"))
        record_date = parse_date(value_for(row, "recordDate"))
        amount = value_for(row, "unadjustedValue", "value")
        return nil if ex_date.blank? || amount.blank?

        {
          ticker_symbol: ticker_symbol,
          amount: amount,
          qualification_date: record_date || ex_date,
          payment_date: payment_date,
          year: ex_date.year,
          interim: interim_dividend?(row, ex_date),
          currency: value_for(row, "currency") || "NGN",
          source: "EODHD"
        }
      end

      def interim_dividend?(row, ex_date)
        period = value_for(row, "period").to_s.downcase
        return true if period.include?("interim")
        return false if period.include?("final")

        ex_date.month >= 7
      end

      def eodhd_symbol(ticker_symbol)
        "#{ticker_symbol.to_s.upcase}.#{@exchange_code}"
      end

      def get_json(path, params = {})
        uri = URI.join("#{@base_url}/", path.to_s.delete_prefix("/"))
        query = params.merge(api_token: @api_key, fmt: "json").compact
        uri.query = URI.encode_www_form(query)

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: TIMEOUT, open_timeout: TIMEOUT) do |http|
          http.get(uri)
        end

        return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

        raise APIError, "HTTP #{response.code}: #{response.body}"
      rescue JSON::ParserError => e
        raise APIError, "Invalid JSON response: #{e.message}"
      end

      def value_for(hash, *keys)
        keys.each do |key|
          value = hash[key] || hash[key.to_sym]
          return value if value.present?
        end
        nil
      end

      def parse_date(value)
        return nil if value.blank?

        value.is_a?(Date) ? value : Date.parse(value.to_s)
      rescue StandardError
        nil
      end
    end
  end
end
