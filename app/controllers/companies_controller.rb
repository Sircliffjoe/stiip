class CompaniesController < ApplicationController
  def index
    @companies = Company.all
  end

  def show
    @company = Company.find_by!(ticker_symbol: params[:ticker_symbol])
    @login_required = !current_access_policy.can_view_company_details?
    @price_data = format_price_data
  end

  private

  def format_price_data
    return [] if @login_required

    prices = @company.stock_prices.order(date: :asc)
    prices = prices.where("date >= ?", current_access_policy.price_history_start_date) unless current_access_policy.can_view_full_price_history?
    prices.map { |price| [price.date.to_s, price.close] }
  end
end
