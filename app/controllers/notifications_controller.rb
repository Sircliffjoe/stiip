class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.order(created_at: :desc)
  end

  def update
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!

    redirect_back fallback_location: notifications_path, notice: "Notification marked as read."
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current, updated_at: Time.current)

    redirect_to notifications_path, notice: "All notifications marked as read."
  end
end
