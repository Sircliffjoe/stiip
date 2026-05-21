class CompaniesController < ApplicationController
  def index
    @companies = Company.all
  end

  def show
    @company = Company.find_by!(ticker_symbol: params[:ticker_symbol])
  end
end
