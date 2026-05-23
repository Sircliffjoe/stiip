class GenerateAlertsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[GenerateAlertsJob] Starting alert generation for watchlist users"

    Notifications::AlertsGenerator.new.call

    Rails.logger.info "[GenerateAlertsJob] Alert generation completed."
  rescue StandardError => e
    Rails.logger.error "[GenerateAlertsJob] Failed: #{e.message}"
    raise
  end
end
