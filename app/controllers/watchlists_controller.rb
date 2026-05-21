class WatchlistsController < ApplicationController
  before_action :authenticate_user!
  def index
    @watchlists = current_user.watchlists
  end
  def show
    @watchlist = current_user.watchlists.find(params[:id])
  end
end
