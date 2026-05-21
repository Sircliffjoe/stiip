class Company < ApplicationRecord
  belongs_to :sector
  has_many :stock_prices, dependent: :destroy
  has_many :dividends, dependent: :destroy
  has_many :watchlist_items, dependent: :destroy
  has_many :company_news, dependent: :destroy
  has_many :news_articles, through: :company_news
  has_many :market_events, dependent: :destroy

  validates :name, presence: true
  validates :ticker_symbol, presence: true, uniqueness: true

  def latest_price
    current_price || stock_prices.order(date: :desc).first&.close
  end

  def pe_ratio_explanation
    return "No data available." unless pe_ratio
    
    if pe_ratio < 10
      "This stock might be undervalued compared to its earnings. (PE: #{pe_ratio})"
    elsif pe_ratio > 25
      "This stock is priced high relative to its earnings, meaning investors expect high growth. (PE: #{pe_ratio})"
    else
      "This stock is reasonably priced relative to its earnings. (PE: #{pe_ratio})"
    end
  end
end
