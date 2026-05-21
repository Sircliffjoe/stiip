class Admin::DividendsController < Admin::ApplicationController
  def index
    @dividends = Dividend.includes(:company).order(qualification_date: :desc)
  end
end
