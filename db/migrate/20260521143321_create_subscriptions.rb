class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :plan, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :starts_at
      t.datetime :expires_at
      t.string :payment_reference

      t.timestamps
    end
  end
end
