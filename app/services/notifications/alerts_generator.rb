module Notifications
  class AlertsGenerator
    PRICE_SWING_THRESHOLD = 5.0  # percent
    HIGH_YIELD_THRESHOLD  = 10.0 # percent

    def call
      users_with_watchlists.find_each do |user|
        generate_price_alerts(user)
        generate_dividend_alerts(user)
      end
    end

    private

    def users_with_watchlists
      User.joins(watchlists: :watchlist_items).distinct
    end

    def generate_price_alerts(user)
      watched_companies = user.watchlist_items.includes(:company).map(&:company).uniq

      watched_companies.each do |company|
        latest_prices = company.stock_prices.order(date: :desc).limit(2)
        next unless latest_prices.size == 2

        today = latest_prices.first
        yesterday = latest_prices.last
        next unless today.close && yesterday.close && yesterday.close > 0

        change_pct = ((today.close - yesterday.close) / yesterday.close * 100).round(2)
        next if change_pct.abs < PRICE_SWING_THRESHOLD

        # Avoid duplicate alerts for the same day
        existing = Notification.where(
          user: user,
          notifiable: company,
          notification_type: "price_alert"
        ).where("created_at >= ?", Date.current.beginning_of_day)
        next if existing.exists?

        direction = change_pct > 0 ? "📈 up" : "📉 down"
        Notification.create!(
          user: user,
          title: "#{company.ticker_symbol} moved #{direction} #{change_pct.abs}%",
          body: "#{company.name} closed at ₦#{today.close} (#{direction} #{change_pct.abs}% from ₦#{yesterday.close}).",
          notification_type: "price_alert",
          notifiable: company
        )
      end
    end

    def generate_dividend_alerts(user)
      watched_companies = user.watchlist_items.includes(:company).map(&:company).uniq

      watched_companies.each do |company|
        upcoming = company.dividends
                         .where(status: "announced")
                         .where("qualification_date > ? AND qualification_date <= ?", Date.current, 14.days.from_now)

        upcoming.each do |dividend|
          existing = Notification.where(
            user: user,
            notifiable: dividend,
            notification_type: "dividend_alert"
          ).where("created_at >= ?", 7.days.ago)
          next if existing.exists?

          Notification.create!(
            user: user,
            title: "Dividend Alert: #{company.ticker_symbol}",
            body: "#{company.name} has an upcoming ₦#{dividend.amount} dividend. Qualify by #{dividend.qualification_date.strftime('%b %d, %Y')}.",
            notification_type: "dividend_alert",
            notifiable: dividend
          )
        end
      end
    end
  end
end
