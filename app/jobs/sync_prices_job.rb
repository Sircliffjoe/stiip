class SyncPricesJob < ApplicationJob
  queue_as :default

  def perform(provider_name = "market")
    Rails.logger.info "[SyncPricesJob] Starting stock price sync with provider: #{provider_name}"

    coordinator = DataIngestion::SyncCoordinator.new(provider: provider_name.to_sym)
    result = coordinator.sync_stock_prices

    Rails.logger.info "[SyncPricesJob] Completed. #{result[:count] || 0} records synced."
    
    # Enqueue alert generation after prices sync
    GenerateAlertsJob.perform_later
  rescue StandardError => e
    Rails.logger.error "[SyncPricesJob] Failed: #{e.message}"
    raise # Re-raise so Solid Queue can retry
  end
end
