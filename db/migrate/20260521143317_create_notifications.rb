class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.text :body
      t.string :notification_type
      t.datetime :read_at
      t.references :notifiable, polymorphic: true, type: :uuid

      t.timestamps
    end
  end
end
