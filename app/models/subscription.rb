class Subscription < ApplicationRecord
  belongs_to :user

  enum :plan, { free: 0, premium: 1, business_api: 2 }
  enum :status, { pending: 0, active: 1, cancelled: 2, expired: 3 }

  validates :plan, presence: true
  validates :status, presence: true
end
