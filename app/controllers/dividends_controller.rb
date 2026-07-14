class DividendsController < ApplicationController
  def index
    @dividends = Dividend.includes(:company).order(payment_date: :desc)
  end
end
