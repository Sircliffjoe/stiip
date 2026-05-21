class IngestNewsJob < ApplicationJob
  queue_as :low_priority
  
  retry_on DataIngestion::Providers::BaseProvider::APIError, wait: 5.minutes, attempts: 3

  def perform
    provider_class = ENV.fetch('NEWS_PROVIDER', 'MockProvider')
    provider = "DataIngestion::Providers::#{provider_class}".constantize.new
    
    DataIngestion::FetchNews.new(provider: provider).call(limit: 50)
    
    AuditLog.create!(action: 'news_ingestion', details: "Ingested latest market news")
  end
end
