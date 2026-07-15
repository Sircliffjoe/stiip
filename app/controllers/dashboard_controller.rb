class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @watchlists = current_user.watchlists
    @smart_insights = build_smart_insights
    @smart_insight = select_smart_insight(@smart_insights)
  end

  private

  def build_smart_insights
    insights = []

    high_yield = Company.where.not(dividend_yield: nil).where("dividend_yield > 0").order(dividend_yield: :desc).first
    if high_yield
      insights << {
        title: "High Yield Alert",
        body: "#{high_yield.name} currently has the platform's highest recorded dividend yield at #{high_yield.dividend_yield.to_f.round(2)}%.",
        path: company_path(high_yield.ticker_symbol),
        label: "View company"
      }
    end

    price_mover = strongest_price_mover
    if price_mover
      company, change = price_mover
      direction = change.negative? ? "down" : "up"
      insights << {
        title: "Price Movement",
        body: "#{company.name} is #{direction} #{change.abs.round(2)}% from its opening price based on the latest available platform data.",
        path: company_path(company.ticker_symbol),
        label: "Review movement"
      }
    end

    buy_signal = Company.buy.order(ytd_return: :desc).first
    if buy_signal
      insights << {
        title: "Buy Signal Watch",
        body: "#{buy_signal.name} is currently marked as a Buy signal with #{buy_signal.ytd_return.to_f.round(2)}% YTD return.",
        path: company_path(buy_signal.ticker_symbol),
        label: "Open signal"
      }
    end

    latest_dividend = Dividend.includes(:company).where.not(qualification_date: nil).order(qualification_date: :desc).first
    if latest_dividend
      insights << {
        title: "Dividend Calendar",
        body: "#{latest_dividend.company.ticker_symbol} has a dividend record of #{helpers.number_to_currency(latest_dividend.amount, unit: "₦")} with qualification date #{latest_dividend.qualification_date.strftime("%b %d, %Y")}.",
        path: dividends_path,
        label: "View dividends"
      }
    end

    latest_news = NewsArticle.published.order(published_at: :desc).first
    if latest_news
      insights << {
        title: "Fresh Market News",
        body: latest_news.title,
        path: news_article_path(latest_news.slug),
        label: "Read news"
      }
    end

    if insights.empty?
      insights << {
        title: "Market Setup",
        body: "NoraCapital is ready. Add companies to your watchlist to unlock more personalized insights.",
        path: watchlists_path,
        label: "Create watchlist"
      }
    end

    insights
  end

  def select_smart_insight(insights)
    insights[(Time.current.to_i / 30) % insights.size]
  end

  def strongest_price_mover
    Company.where.not(current_price: nil, opening_price: nil)
      .where("opening_price > 0")
      .map { |company| [company, ((company.current_price - company.opening_price) / company.opening_price * 100).to_f] }
      .max_by { |_company, change| change.abs }
  end
end
