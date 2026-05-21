class DividendsController < ApplicationController
  def index
    @dividends = Dividend.includes(:company).order(qualification_date: :asc).limit(20)
  end
end
