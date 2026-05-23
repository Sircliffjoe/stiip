class SyncNewsJob < ApplicationJob
  queue_as :default

  def perform(provider_name = "mock")
    Rails.logger.info "[SyncNewsJob] Starting news sync with provider: #{provider_name}"

    coordinator = DataIngestion::SyncCoordinator.new(provider_name)
    result = coordinator.sync_news

    Rails.logger.info "[SyncNewsJob] Completed. #{result[:records_synced] || 0} records synced."
  rescue StandardError => e
    Rails.logger.error "[SyncNewsJob] Failed: #{e.message}"
    raise
  end
end
