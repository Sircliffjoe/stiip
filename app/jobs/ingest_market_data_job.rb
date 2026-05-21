class IngestMarketDataJob < ApplicationJob
  queue_as :default
  
  # Retry on specific API failures
  retry_on DataIngestion::Providers::BaseProvider::APIError, wait: :exponentially_longer, attempts: 3

  def perform(date_string = Date.current.to_s)
    date = Date.parse(date_string)
    
    # Determine Provider (Can be switched out in production via ENV)
    provider_class = ENV.fetch('MARKET_DATA_PROVIDER', 'MockProvider')
    provider = "DataIngestion::Providers::#{provider_class}".constantize.new
    
    # Fetch End of Day Prices
    DataIngestion::FetchStockPrices.new(provider: provider).call(date: date)
    
    # Fetch Dividends for the month
    DataIngestion::FetchDividends.new(provider: provider).call
    
    # Log completion
    AuditLog.create!(action: 'market_data_ingestion', details: "Ingested EOD prices and dividends for #{date}")
  end
end
