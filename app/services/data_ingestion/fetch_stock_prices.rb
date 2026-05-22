module DataIngestion
  class FetchStockPrices
    def initialize(provider: Providers::MockProvider.new)
      @provider = provider
      @normalizer = DataNormalizer.new
    end

    def call(date: Date.current)
      raw_data = @provider.fetch_end_of_day_prices(date: date)
      normalized_data = normalize_data(raw_data)
      persist_data(normalized_data, date)
    end

    private

    def normalize_data(raw_data)
      raw_data.map do |data|
        @normalizer.normalize_price(data)
      rescue DataNormalizer::ValidationError => e
        Rails.logger.warn("[FetchStockPrices] Validation error for #{data[:ticker_symbol]}: #{e.message}")
        nil
      end.compact
    end

    def persist_data(normalized_data, date)
      count = 0
      ActiveRecord::Base.transaction do
        normalized_data.each do |data|
          company = Company.find_by(ticker_symbol: data[:ticker_symbol])
          next unless company

          stock_price = StockPrice.find_or_initialize_by(company: company, date: data[:date])
          stock_price.update!(
            open: data[:open],
            high: data[:high],
            low: data[:low],
            close: data[:close],
            volume: data[:volume]
          )

          company.update!(current_price: data[:close]) if data[:close]
          count += 1
        end
      end
      count
    end
  end
end
