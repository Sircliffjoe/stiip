class Company < ApplicationRecord
  require "uri"

  include PgSearch::Model
  multisearchable against: [:name, :ticker_symbol, :description]
  pg_search_scope :search_by_term, against: [:name, :ticker_symbol, :description],
                  using: { tsearch: { prefix: true, dictionary: "english" } }

  belongs_to :sector
  has_many :stock_prices, dependent: :destroy
  has_many :dividends, dependent: :destroy
  has_many :watchlist_items, dependent: :destroy
  has_many :company_news, dependent: :destroy
  has_many :news_articles, through: :company_news
  has_many :market_events, dependent: :destroy

  enum :signal, { hold: 1, buy: 2, sell: 3 }

  scope :ngx, -> { where(country: "NG") }
  scope :us, -> { where(country: "US") }

  validates :name, presence: true
  validates :ticker_symbol, presence: true, uniqueness: true

  def latest_price
    current_price || stock_prices.order(date: :desc).first&.close
  end

  def logo_source(size: 128)
    normalized_logo_url.presence || website_favicon_url(size: size)
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

  private

  def normalized_logo_url
    normalize_external_url(logo_url)
  end

  def website_favicon_url(size:)
    website_uri = URI.parse(normalize_external_url(website).to_s)
    host = website_uri.host
    return nil if host.blank?

    URI::HTTPS.build(
      host: "www.google.com",
      path: "/s2/favicons",
      query: URI.encode_www_form(domain: host, sz: size.to_i.clamp(16, 256))
    ).to_s
  rescue URI::InvalidURIError
    nil
  end

  def normalize_external_url(value)
    return nil if value.blank?

    url = value.to_s.strip
    url = "https://#{url}" unless url.match?(%r{\Ahttps?://}i)
    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTP) && uri.host.present?

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
