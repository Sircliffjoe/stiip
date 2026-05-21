class CreateStockPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_prices, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.date :date, null: false
      t.decimal :open, precision: 15, scale: 2
      t.decimal :close, precision: 15, scale: 2
      t.decimal :high, precision: 15, scale: 2
      t.decimal :low, precision: 15, scale: 2
      t.bigint :volume
      t.decimal :change_percent, precision: 8, scale: 2

      t.timestamps
    end
    add_index :stock_prices, [:company_id, :date], unique: true
  end
end
