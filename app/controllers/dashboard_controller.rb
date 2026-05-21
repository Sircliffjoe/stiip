class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @watchlists = current_user.watchlists
  end
end
