class WatchlistItem < ApplicationRecord
  belongs_to :watchlist
  belongs_to :company

  validates :company_id, uniqueness: { scope: :watchlist_id, message: "Company already in watchlist" }
end
