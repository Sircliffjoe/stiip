module DataIngestion
  module Providers
    class CsvProvider < BaseProvider
      require "csv"

      # Expected CSV columns: ticker_symbol, date, open, high, low, close, volume
      # or: ticker_symbol, date, close, volume (minimal)
      
      def initialize(file_path:)
        @file_path = file_path
      end

      def fetch_end_of_day_prices(date: Date.current)
        raise ArgumentError, "File not found: #{@file_path}" unless File.exist?(@file_path)

        handle_request do
          data = []
          CSV.foreach(@file_path, headers: true) do |row|
            data << normalize_price_row(row.to_h)
          end
          data
        end
      end

      def fetch_dividends(start_date:, end_date:)
        raise ArgumentError, "File not found: #{@file_path}" unless File.exist?(@file_path)

        # CSV provider can also handle dividend data if formatted correctly
        # Expected columns: ticker_symbol, amount, qualification_date, payment_date, year
        handle_request do
          data = []
          CSV.foreach(@file_path, headers: true) do |row|
            next unless row["ticker_symbol"]
            data << normalize_dividend_row(row.to_h, start_date, end_date)
          end
          data.compact
        end
      end

      def fetch_news(limit: 20)
        raise ArgumentError, "File not found: #{@file_path}" unless File.exist?(@file_path)

        # CSV provider for news: title, content, source, url, published_at, related_tickers
        handle_request do
          data = []
          CSV.foreach(@file_path, headers: true) do |row|
            break if data.size >= limit
            data << normalize_news_row(row.to_h) if row["title"]
          end
          data
        end
      end

      private

      def normalize_price_row(row)
        {
          ticker_symbol: row["ticker_symbol"]&.upcase&.strip,
          date: parse_date(row["date"]),
          open: parse_float(row["open"]),
          high: parse_float(row["high"]),
          low: parse_float(row["low"]),
          close: parse_float(row["close"]),
          volume: parse_integer(row["volume"])
        }.tap do |data|
          # Fill in missing OHLC fields with close price if available
          if data[:close] && data[:open].nil?
            data[:open] = data[:close]
            data[:high] = data[:close]
            data[:low] = data[:close]
          end
        end
      end

      def normalize_dividend_row(row, start_date, end_date)
        qualification_date = parse_date(row["qualification_date"])
        payment_date = parse_date(row["payment_date"])
        
        # Skip if dates are outside range
        return nil if qualification_date && (qualification_date < start_date || qualification_date > end_date)
        
        {
          ticker_symbol: row["ticker_symbol"]&.upcase&.strip,
          amount: parse_float(row["amount"]),
          qualification_date: qualification_date,
          payment_date: payment_date,
          year: parse_integer(row["year"]) || Date.today.year
        }
      end

      def normalize_news_row(row)
        {
          title: row["title"]&.strip,
          content: row["content"]&.strip,
          source: row["source"]&.strip || "CSV Import",
          url: row["url"]&.strip,
          published_at: parse_datetime(row["published_at"]) || Time.current,
          related_tickers: parse_tickers(row["related_tickers"])
        }
      end

      def parse_date(value)
        return nil if value.blank?
        Date.parse(value.to_s)
      rescue StandardError
        nil
      end

      def parse_datetime(value)
        return nil if value.blank?
        Time.parse(value.to_s)
      rescue StandardError
        nil
      end

      def parse_float(value)
        return nil if value.blank?
        Float(value.to_s)
      rescue StandardError
        nil
      end

      def parse_integer(value)
        return nil if value.blank?
        Integer(value.to_s)
      rescue StandardError
        nil
      end

      def parse_tickers(value)
        return [] if value.blank?
        value.to_s.split(",").map { |t| t.upcase.strip }.compact.uniq
      end
    end
  end
end
