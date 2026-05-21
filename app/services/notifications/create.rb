module Notifications
  class Create
    def initialize(user:, title:, message:, type: 'info', url: nil)
      @user = user
      @title = title
      @message = message
      @type = type
      @url = url
    end

    def call
      notification = @user.notifications.create!(
        title: @title,
        message: @message,
        notification_type: @type,
        action_url: @url
      )

      broadcast(notification)
      notification
    end

    private

    def broadcast(notification)
      NotificationsChannel.broadcast_to(
        @user,
        {
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.notification_type,
          url: notification.action_url,
          created_at: notification.created_at.strftime('%l:%M %p')
        }
      )
    end
  end
end
