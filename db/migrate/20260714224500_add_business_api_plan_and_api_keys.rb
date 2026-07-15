class AddBusinessApiPlanAndApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :token_prefix, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.datetime :expires_at
      t.integer :requests_count, null: false, default: 0
      t.integer :monthly_requests_count, null: false, default: 0
      t.datetime :monthly_requests_reset_at
      t.integer :rate_limit_per_minute, null: false, default: 120
      t.integer :monthly_quota, null: false, default: 100_000

      t.timestamps
    end

    add_index :api_keys, :token_prefix, unique: true

    reversible do |dir|
      dir.up do
        User.reset_column_information
        Subscription.reset_column_information

        User.find_each do |user|
          next if user.subscription.present?

          plan = user.business_api_role? ? :business_api : (user.premium? ? :premium : :free)
          Subscription.create!(
            user: user,
            plan: plan,
            status: :active,
            starts_at: Time.current
          )
        end
      end
    end
  end
end
