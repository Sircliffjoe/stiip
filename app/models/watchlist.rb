class Watchlist < ApplicationRecord
  belongs_to :user
  has_many :watchlist_items, dependent: :destroy
  has_many :companies, through: :watchlist_items

  validates :name, presence: true
end
