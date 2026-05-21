class MarketEvent < ApplicationRecord
  belongs_to :company, optional: true

  enum :event_type, { general_news: 0, earnings_report: 1, dividend_announcement: 2, agm: 3 }

  validates :title, presence: true
  validates :event_date, presence: true
end
