class DividendsController < ApplicationController
  DEFAULT_PAGE_SIZE = 25
  MAX_PAGE_SIZE = 200

  def index
    @login_required = !user_signed_in?
    @premium_required = user_signed_in? && !current_access_policy.can_use_advanced_dividends?
    @selected_tab = params[:tab].presence_in(%w[historical upcoming]) || "historical"
    @historical_limit = limit_param(:historical_limit)
    @upcoming_limit = limit_param(:upcoming_limit)
    dividends_scope = Dividend.includes(:company)

    upcoming_scope = dividends_scope
      .where("COALESCE(payment_date, qualification_date) >= ?", Date.current)
      .order(Arel.sql("COALESCE(payment_date, qualification_date) ASC"))

    historical_scope = dividends_scope
      .where("COALESCE(payment_date, qualification_date) < ? OR (payment_date IS NULL AND qualification_date IS NULL)", Date.current)
      .order(Arel.sql("COALESCE(payment_date, qualification_date, make_date(year, 1, 1)) DESC"))

    @historical_total_count = historical_scope.count
    @upcoming_total_count = upcoming_scope.count

    if @premium_required
      @historical_limit = [@historical_limit, 20].min
      @upcoming_limit = [@upcoming_limit, 10].min
    end

    @historical_dividends = historical_scope.limit(@historical_limit)
    @upcoming_dividends = upcoming_scope.limit(@upcoming_limit)

    if @login_required
      @historical_dividends = Dividend.none
      @upcoming_dividends = Dividend.none
      @historical_total_count = 0
      @upcoming_total_count = 0
    end

    @dividend_analytics = if user_signed_in? && !@premium_required
                            Dividends::Analytics.new(historical_scope.to_a).summary
                          end
  end

  private

  def limit_param(key)
    params.fetch(key, DEFAULT_PAGE_SIZE).to_i.clamp(DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE)
  end
end
