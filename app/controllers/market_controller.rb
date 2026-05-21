class MarketController < ApplicationController
  def index
    @companies = Company.all.limit(5)
    @sectors = Sector.all
  end
end
