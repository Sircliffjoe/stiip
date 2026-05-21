class StockPrice < ApplicationRecord
  belongs_to :company

  validates :date, presence: true
  validates :date, uniqueness: { scope: :company_id, message: "Price already recorded for this date" }
end
