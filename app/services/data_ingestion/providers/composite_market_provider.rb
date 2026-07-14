module DataIngestion
  module Providers
    class CompositeMarketProvider < BaseProvider
      def initialize(providers: default_providers)
        @providers = providers
      end

      def fetch_end_of_day_prices(date: Date.current)
        merge_price_rows(fetch_from_providers(:fetch_end_of_day_prices, date: date))
      end

      def fetch_stock_price(symbol, date: Date.current)
        merge_price_rows(fetch_from_providers(:fetch_stock_price, symbol, date: date)).first
      end

      def fetch_companies
        merge_company_rows(fetch_from_providers(:fetch_companies))
      end

      def fetch_dividends(start_date:, end_date:)
        merge_unique_rows(fetch_from_providers(:fetch_dividends, start_date: start_date, end_date: end_date), [:ticker_symbol, :year, :interim])
      end

      def fetch_news(limit: 20)
        merge_unique_rows(fetch_from_providers(:fetch_news, limit: limit), [:url, :title]).first(limit)
      end

      private

      def default_providers
        [
          Providers::NgnMarketProvider.new,
          Providers::EodhdProvider.new,
          Providers::NgxProvider.new
        ]
      end

      def fetch_from_providers(method_name, *args, **kwargs)
        @providers.flat_map do |provider|
          Array(provider.public_send(method_name, *args, **kwargs))
        rescue StandardError => e
          Rails.logger.warn("[CompositeMarketProvider] #{provider.class.name} failed for #{method_name}: #{e.message}")
          []
        end
      end

      def merge_price_rows(rows)
        rows
          .compact
          .group_by { |row| row[:ticker_symbol].to_s.upcase }
          .filter_map { |_ticker, grouped_rows| best_price_row(grouped_rows) }
      end

      def merge_company_rows(rows)
        rows
          .compact
          .group_by { |row| row[:ticker_symbol].to_s.upcase }
          .filter_map { |_ticker, grouped_rows| best_company_row(grouped_rows) }
      end

      def best_price_row(rows)
        rows.max_by do |row|
          [
            row[:source_time] || row[:date]&.to_time || Time.at(0),
            row[:source] == "NGN Market" ? 1 : 0
          ]
        end
      end

      def best_company_row(rows)
        rows.max_by do |row|
          [
            row[:source_time] || Time.at(0),
            row[:source] == "NGN Market" ? 1 : 0
          ]
        end
      end

      def merge_unique_rows(rows, keys)
        seen = {}

        rows.compact.filter_map do |row|
          identity = keys.map { |key| row[key].presence }.compact.join(":").presence
          identity ||= row.hash
          next if seen[identity]

          seen[identity] = true
          row
        end
      end
    end
  end
end
