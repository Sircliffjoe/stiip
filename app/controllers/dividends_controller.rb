class DividendsController < ApplicationController
  def index
    @login_required = !user_signed_in?
    @premium_required = user_signed_in? && !current_access_policy.can_use_advanced_dividends?
    @dividends = Dividend.includes(:company).order(payment_date: :desc)
    @dividends = @dividends.limit(20) if @premium_required
    @dividends = Dividend.none if @login_required
  end
end
