class CompaniesController < ApplicationController
  def index
    @companies = Company.all
  end

  def show
    @company = Company.find_by!(ticker_symbol: params[:ticker_symbol])
    @price_data = format_price_data
  end

  private

  def format_price_data
    prices = premium_user? ? @company.stock_prices.order(date: :asc) : @company.stock_prices.where("date >= ?", 30.days.ago).order(date: :asc)
    prices.map { |price| [price.date.to_s, price.close] }
  end
end
