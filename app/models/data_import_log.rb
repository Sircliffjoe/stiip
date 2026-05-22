class DataImportLog < ApplicationRecord
  belongs_to :imported_by, class_name: "User", foreign_key: "user_id", optional: true

  validates :data_type, presence: true
  validates :provider, presence: true
  validates :status, presence: true, inclusion: { in: %w(pending success failed) }

  enum :status, { pending: "pending", success: "success", failed: "failed" }

  scope :by_type, ->(type) { where(data_type: type) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: :success) }
  scope :failed, -> { where(status: :failed) }

  def self.import_stats(period = 30.days)
    where("created_at > ?", period.ago).group(:data_type).count
  end

  def self.success_rate(period = 30.days)
    logs = where("created_at > ?", period.ago)
    return 0.0 if logs.empty?
    
    successful = logs.successful.count
    total = logs.count
    (successful.to_f / total * 100).round(2)
  end
end
