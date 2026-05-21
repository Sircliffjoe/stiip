class Admin::StockPricesController < Admin::ApplicationController
  def index
    @recent_prices = StockPrice.includes(:company).order(date: :desc).limit(50)
  end
  
  def import
    # TODO: Implement CSV parsing and insertion
    flash[:notice] = "CSV upload functionality coming soon."
    redirect_to admin_stock_prices_path
  end
end
