class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @watchlists_count = current_user.watchlists.count
    @notifications_count = current_user.notifications.unread.count
  end

  def edit
    @user = current_user
  end
end
