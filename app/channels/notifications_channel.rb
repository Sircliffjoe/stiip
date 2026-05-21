class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
  
  def mark_as_read(data)
    notification = current_user.notifications.find_by(id: data['id'])
    notification&.mark_as_read!
  end
end
