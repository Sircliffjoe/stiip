class CreateDividends < ActiveRecord::Migration[8.0]
  def change
    create_table :dividends, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :currency, default: "NGN", null: false
      t.date :qualification_date
      t.date :payment_date
      t.integer :year, null: false
      t.boolean :interim, default: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :dividends, [:company_id, :year, :interim], unique: true
  end
end
