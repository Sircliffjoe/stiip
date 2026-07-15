module DataIngestion
  module Providers
    class EodhdProvider < BaseProvider
      require "json"
      require "net/http"
      require "uri"

      BASE_URL = "https://eodhd.com/api".freeze
      EXCHANGE_CODE = "XNSA".freeze
      TIMEOUT = 8.freeze

      def initialize(api_key: ENV["EODHD_API_KEY"], base_url: BASE_URL, exchange_code: ENV["EODHD_EXCHANGE_CODE"].presence || EXCHANGE_CODE, exchange_codes: nil)
        @api_key = api_key
        @base_url = base_url
        @exchange_codes = Array(exchange_codes.presence || ENV["EODHD_EXCHANGE_CODES"].presence || exchange_code)
          .flat_map { |value| value.to_s.split(",") }
          .map { |value| value.strip.upcase.delete_prefix(".") }
          .reject(&:blank?)
        @exchange_codes = [EXCHANGE_CODE] if @exchange_codes.empty?
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
        handle_request do
          rows = fetch_topic_news(limit)
          rows += fetch_symbol_news(limit) if rows.length < limit

          rows
            .uniq { |row| row[:url].presence || row[:title] }
            .sort_by { |row| row[:published_at] || Time.at(0) }
            .reverse
            .first(limit)
        end
      end

      private

      def fetch_company_dividends(ticker_symbol, start_date, end_date)
        rows = []
        attempted_symbols.each do |exchange_code|
          symbol = eodhd_symbol(ticker_symbol, exchange_code)
          rows = get_json("/div/#{symbol}", from: start_date.to_date.to_s, to: end_date.to_date.to_s)
          break if Array(rows).any?
        rescue APIError => e
          Rails.logger.warn("[EodhdProvider] Dividend fetch failed for #{symbol}: #{e.message}")
        end

        Array(rows).filter_map do |row|
          normalize_dividend(ticker_symbol, row)
        end
      rescue StandardError => e
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

      def fetch_topic_news(limit)
        news_tags.flat_map do |tag|
          fetch_news_rows(t: tag, limit: per_source_limit(limit))
        rescue APIError => e
          Rails.logger.warn("[EodhdProvider] News tag fetch failed for #{tag}: #{e.message}")
          []
        end
      end

      def fetch_symbol_news(limit)
        news_symbols.first(news_symbol_limit).flat_map do |symbol|
          fetch_news_rows(s: symbol, limit: per_source_limit(limit))
        rescue APIError => e
          Rails.logger.warn("[EodhdProvider] News symbol fetch failed for #{symbol}: #{e.message}")
          []
        end
      end

      def fetch_news_rows(params)
        rows = get_json("/news", params.merge(offset: 0))

        Array(rows).filter_map do |row|
          normalize_news(row)
        end
      end

      def normalize_news(row)
        title = value_for(row, "title")
        url = value_for(row, "link", "url")
        return nil if title.blank? || url.blank?

        {
          title: title,
          content: value_for(row, "content", "description", "summary"),
          source: news_source_name(url),
          url: url,
          published_at: parse_time(value_for(row, "date", "published_at", "publishedAt")),
          related_tickers: normalize_news_symbols(value_for(row, "symbols"))
        }
      end

      def news_tags
        ENV.fetch("EODHD_NEWS_TAGS", "NIGERIA,ECONOMY,FINANCIAL MARKETS,INVESTMENT,BANKING")
          .split(",")
          .map { |tag| tag.strip }
          .reject(&:blank?)
      end

      def news_symbol_limit
        ENV.fetch("EODHD_NEWS_SYMBOL_LIMIT", 10).to_i.clamp(0, 50)
      end

      def news_symbols
        Company
          .where(listed: true)
          .order(Arel.sql("market_cap DESC NULLS LAST"), :ticker_symbol)
          .limit(news_symbol_limit)
          .flat_map { |company| attempted_symbols.map { |exchange_code| eodhd_symbol(company.ticker_symbol, exchange_code) } }
      end

      def per_source_limit(total_limit)
        [total_limit.to_i, 100].min.clamp(1, 100)
      end

      def news_source_name(url)
        URI.parse(url.to_s).host.to_s.delete_prefix("www.").presence || "EODHD"
      rescue URI::InvalidURIError
        "EODHD"
      end

      def normalize_news_symbols(symbols)
        Array(symbols).filter_map do |symbol|
          symbol.to_s.split(".").first.presence
        end
      end

      def attempted_symbols
        @exchange_codes
      end

      def eodhd_symbol(ticker_symbol, exchange_code)
        "#{ticker_symbol.to_s.upcase}.#{exchange_code}"
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

      def parse_time(value)
        return Time.current if value.blank?

        value.is_a?(Time) ? value : Time.parse(value.to_s)
      rescue StandardError
        Time.current
      end
    end
  end
end
