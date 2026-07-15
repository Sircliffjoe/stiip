class ApiKey < ApplicationRecord
  TOKEN_PREFIX_LENGTH = 18

  belongs_to :user

  attr_reader :plain_token

  validates :name, presence: true
  validates :token_digest, presence: true
  validates :token_prefix, presence: true, uniqueness: true
  validates :rate_limit_per_minute, numericality: { only_integer: true, greater_than: 0 }
  validates :monthly_quota, numericality: { only_integer: true, greater_than: 0 }

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  before_validation :generate_token, on: :create
  before_validation :set_monthly_reset, on: :create

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    prefix = raw_token.first(TOKEN_PREFIX_LENGTH)
    active.find_by(token_prefix: prefix)&.then do |api_key|
      BCrypt::Password.new(api_key.token_digest).is_password?(raw_token) ? api_key : nil
    end
  rescue BCrypt::Errors::InvalidHash
    nil
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def record_request!
    reset_monthly_usage_if_needed!
    increment!(:requests_count)
    increment!(:monthly_requests_count)
    touch(:last_used_at)
  end

  def monthly_quota_exceeded?
    reset_monthly_usage_if_needed!
    monthly_requests_count >= monthly_quota
  end

  private

  def generate_token
    return if token_digest.present?

    @plain_token = "nora_live_#{SecureRandom.base58(40)}"
    self.token_prefix = @plain_token.first(TOKEN_PREFIX_LENGTH)
    self.token_digest = BCrypt::Password.create(@plain_token)
  end

  def set_monthly_reset
    self.monthly_requests_reset_at ||= 1.month.from_now
  end

  def reset_monthly_usage_if_needed!
    return if monthly_requests_reset_at.present? && monthly_requests_reset_at.future?

    update_columns(monthly_requests_count: 0, monthly_requests_reset_at: 1.month.from_now, updated_at: Time.current)
    reload
  end
end
