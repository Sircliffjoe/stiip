class WatchlistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_watchlist, only: [:show, :edit, :update, :destroy]

  def index
    @watchlists = current_user.watchlists.includes(:companies).order(created_at: :asc)
    @watchlist = current_user.watchlists.build
  end

  def show
    @companies = Company.includes(:sector).order(:ticker_symbol)
    @watchlist_items = @watchlist.watchlist_items.includes(company: :sector).order(created_at: :desc)
  end

  def new
    @watchlist = current_user.watchlists.build
  end

  def create
    @watchlist = current_user.watchlists.build(watchlist_params)
    @watchlist.is_default = current_user.watchlists.none?

    if @watchlist.save
      redirect_to @watchlist, notice: "Watchlist created."
    else
      @watchlists = current_user.watchlists.includes(:companies).order(created_at: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @watchlist.update(watchlist_params)
      redirect_to @watchlist, notice: "Watchlist updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @watchlist.destroy
    redirect_to watchlists_path, notice: "Watchlist deleted."
  end

  private

  def set_watchlist
    @watchlist = current_user.watchlists.find(params[:id])
  end

  def watchlist_params
    params.require(:watchlist).permit(:name)
  end
end
