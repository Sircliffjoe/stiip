class Admin::UsersController < Admin::ApplicationController
  def index
    @users = User.all.order(created_at: :desc)
  end
end
