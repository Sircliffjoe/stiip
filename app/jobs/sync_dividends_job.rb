class SyncDividendsJob < ApplicationJob
  queue_as :default

  def perform(provider_name = "eodhd")
    Rails.logger.info "[SyncDividendsJob] Starting dividend sync with provider: #{provider_name}"

    coordinator = DataIngestion::SyncCoordinator.new(provider: provider_name.to_sym)
    result = coordinator.sync_dividends

    Rails.logger.info "[SyncDividendsJob] Completed. #{result[:count] || 0} records synced."
    
    # Enqueue alert generation after dividends sync
    GenerateAlertsJob.perform_later
  rescue StandardError => e
    Rails.logger.error "[SyncDividendsJob] Failed: #{e.message}"
    raise
  end
end
