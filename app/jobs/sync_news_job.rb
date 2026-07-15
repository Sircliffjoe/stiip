class SyncNewsJob < ApplicationJob
  queue_as :default

  def perform(provider_name = "market")
    Rails.logger.info "[SyncNewsJob] Starting news sync with provider: #{provider_name}"

    coordinator = DataIngestion::SyncCoordinator.new(provider: provider_name.to_sym)
    result = coordinator.sync_news

    if result[:success]
      Rails.logger.info "[SyncNewsJob] Completed. #{result[:count] || 0} records synced."
    else
      Rails.logger.error "[SyncNewsJob] Failed: #{result[:error]}"
    end
  rescue StandardError => e
    Rails.logger.error "[SyncNewsJob] Failed: #{e.message}"
    raise
  end
end
