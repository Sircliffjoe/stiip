class Admin::DashboardController < Admin::ApplicationController
  def index
    @users_count = User.count
    @companies_count = Company.count
    @premium_users = User.where(role: User.roles[:premium]).count
    @news_count = NewsArticle.count
    @education_count = EducationalContent.count
    @unread_notifications = Notification.unread.count
  end
end
