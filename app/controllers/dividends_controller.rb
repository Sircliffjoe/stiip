class DividendsController < ApplicationController
  def index
    @login_required = !user_signed_in?
    @premium_required = user_signed_in? && !current_access_policy.can_use_advanced_dividends?
    dividends_scope = Dividend.includes(:company)

    @upcoming_dividends = dividends_scope
      .where("COALESCE(payment_date, qualification_date) >= ?", Date.current)
      .order(Arel.sql("COALESCE(payment_date, qualification_date) ASC"))

    @historical_dividends = dividends_scope
      .where("COALESCE(payment_date, qualification_date) < ? OR (payment_date IS NULL AND qualification_date IS NULL)", Date.current)
      .order(Arel.sql("COALESCE(payment_date, qualification_date, make_date(year, 1, 1)) DESC"))

    if @premium_required
      @historical_dividends = @historical_dividends.limit(20)
      @upcoming_dividends = @upcoming_dividends.limit(10)
    end

    if @login_required
      @historical_dividends = Dividend.none
      @upcoming_dividends = Dividend.none
    end

    @dividend_analytics = if user_signed_in? && !@premium_required
                            Dividends::Analytics.new(@historical_dividends.to_a).summary
                          end
  end
end
