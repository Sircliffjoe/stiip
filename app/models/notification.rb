class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :title, presence: true

  after_create_commit :broadcast_to_user

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  def mark_as_read!
    update(read_at: Time.current)
  end

  private

  def broadcast_to_user
    NotificationsChannel.broadcast_to(
      user,
      id: id,
      title: title,
      message: body,
      notification_type: notification_type,
      created_at: created_at.iso8601
    )
  end
end
