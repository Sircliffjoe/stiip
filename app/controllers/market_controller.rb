class MarketController < ApplicationController
  def index
    @companies = Company.where(listed: true).includes(:sector)
    @latest_prices = latest_market_prices
    @market_news = fetch_market_news
    @top_gainers = top_gainers
    @market_summary = market_summary
    @last_updated_at = last_updated_at
  end

  private

  def fetch_market_news
    NewsArticle.published.includes(:companies).order(published_at: :desc).limit(5)
  end

  def latest_market_prices
    latest_date = StockPrice.maximum(:date)
    return StockPrice.none unless latest_date

    StockPrice
      .joins(:company)
      .merge(Company.where(listed: true))
      .includes(:company)
      .where(date: latest_date)
  end

  def top_gainers
    # Try to get gainers from latest prices with change_percent data
    gainers = @latest_prices
      .where.not(change_percent: nil)
      .order(change_percent: :desc)
      .limit(5)
      .map do |price|
        {
          company: price.company,
          price: price.close,
          change_percent: price.change_percent
        }
      end

    return gainers if gainers.any?

    # Fallback: use all listed companies, sorted by latest price descending
    @companies
      .where.not(listed: false)
      .includes(:stock_prices)
      .sort_by { |c| (c.latest_price || 0).to_d }
      .reverse
      .map do |company|
        {
          company: company,
          price: company.latest_price,
          change_percent: 0.0
        }
      end
      .first(5)
  end

  def market_summary
    average_change = average_market_change_percent
    total_market_cap = @companies.sum(:market_cap).to_d
    total_volume = @latest_prices.sum(:volume).to_d

    {
      all_share_index: 100_000 * (1 + (average_change / 100)),
      average_change_percent: average_change,
      market_cap_trillions: total_market_cap / 1_000_000_000_000,
      market_cap_change_percent: market_cap_change_percent,
      volume_millions: total_volume / 1_000_000
    }
  end

  def average_market_change_percent
    average_change = @latest_prices.where.not(change_percent: nil).average(:change_percent)
    return average_change.to_d if average_change

    changes = @companies
      .select { |company| company.current_price.present? && company.opening_price.to_d.positive? }
      .map { |company| (company.current_price - company.opening_price) / company.opening_price * 100 }

    return 0.to_d if changes.empty?

    (changes.sum / changes.size).to_d
  end

  def market_cap_change_percent
    opening_value = @companies.sum do |company|
      company.opening_price.to_d * company.shares_outstanding.to_d
    end
    current_value = @companies.sum do |company|
      company.latest_price.to_d * company.shares_outstanding.to_d
    end

    return 0.to_d unless opening_value.positive?

    ((current_value - opening_value) / opening_value * 100).round(2)
  end

  def last_updated_at
    [
      @latest_prices.maximum(:updated_at),
      @market_news.maximum(:updated_at),
      @companies.maximum(:updated_at)
    ].compact.max
  end
end
