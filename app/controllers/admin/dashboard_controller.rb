class Admin::DashboardController < Admin::ApplicationController
  def index
    @users_count = User.count
    @companies_count = Company.count
    @premium_users = User.premium.count
  end
end
