class WatchlistItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_watchlist

  def create
    company = Company.find(params[:company_id])
    item = @watchlist.watchlist_items.build(company: company)

    if item.save
      Notification.create!(
        user: current_user,
        title: "#{company.ticker_symbol} added to #{@watchlist.name}",
        body: "You will now see watchlist-driven updates for #{company.name}.",
        notification_type: "watchlist",
        notifiable: company
      )
      redirect_to @watchlist, notice: "#{company.ticker_symbol} added to #{@watchlist.name}."
    else
      redirect_to @watchlist, alert: item.errors.full_messages.to_sentence
    end
  end

  def destroy
    item = @watchlist.watchlist_items.find(params[:id])
    ticker = item.company.ticker_symbol
    item.destroy

    redirect_to @watchlist, notice: "#{ticker} removed from #{@watchlist.name}."
  end

  private

  def set_watchlist
    @watchlist = current_user.watchlists.find(params[:watchlist_id])
  end
end
