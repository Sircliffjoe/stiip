class Dividend < ApplicationRecord
  belongs_to :company

  enum :status, { announced: 0, paid: 1, cancelled: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :year, presence: true
end
