class AddRenewalRemindedAtToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :renewal_reminded_at, :datetime
    add_index :subscriptions, :renewal_reminded_at
  end
end
