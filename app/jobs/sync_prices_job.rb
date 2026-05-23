class SyncPricesJob < ApplicationJob
  queue_as :default

  def perform(provider_name = "mock")
    Rails.logger.info "[SyncPricesJob] Starting stock price sync with provider: #{provider_name}"

    coordinator = DataIngestion::SyncCoordinator.new(provider_name)
    result = coordinator.sync_prices

    Rails.logger.info "[SyncPricesJob] Completed. #{result[:records_synced] || 0} records synced."
    
    # Enqueue alert generation after prices sync
    GenerateAlertsJob.perform_later
  rescue StandardError => e
    Rails.logger.error "[SyncPricesJob] Failed: #{e.message}"
    raise # Re-raise so Solid Queue can retry
  end
end
