module DataIngestion
  class FetchDividends
    def initialize(provider: Providers::MockProvider.new)
      @provider = provider
    end

    def call(start_date: Date.current, end_date: 1.month.from_now)
      raw_data = @provider.fetch_dividends(start_date: start_date, end_date: end_date)
      
      ActiveRecord::Base.transaction do
        raw_data.each do |data|
          company = Company.find_by(ticker_symbol: data[:ticker_symbol])
          next unless company
          
          Dividend.find_or_initialize_by(
            company: company, 
            amount: data[:amount], 
            qualification_date: data[:qualification_date]
          ).tap do |div|
            div.payment_date = data[:payment_date]
            div.year = data[:year]
            div.status = :announced
            div.save!
          end
        end
      end
    end
  end
end
