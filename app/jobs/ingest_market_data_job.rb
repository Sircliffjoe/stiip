class IngestMarketDataJob < ApplicationJob
  queue_as :default
  
  # Retry on specific API failures
  retry_on DataIngestion::Providers::BaseProvider::APIError, wait: :exponentially_longer, attempts: 3

  def perform(date_string = Date.current.to_s)
    date = Date.parse(date_string)

    provider_name = ENV.fetch("MARKET_DATA_PROVIDER", "market").to_sym
    result = DataIngestion::SyncCoordinator.new(provider: provider_name).sync_all(date: date)
    
    # Log completion
    AuditLog.create!(action: "market_data_ingestion", details: "Ingested market data for #{date}: #{result.inspect}")
  end
end
