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
