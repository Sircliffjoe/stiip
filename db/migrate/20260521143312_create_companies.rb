class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies, id: :uuid do |t|
      t.string :name, null: false
      t.string :ticker_symbol, null: false
      t.references :sector, null: false, foreign_key: true, type: :uuid
      t.text :description
      t.decimal :market_cap, precision: 20, scale: 2
      t.decimal :pe_ratio, precision: 10, scale: 2
      t.decimal :current_price, precision: 15, scale: 2
      t.decimal :opening_price, precision: 15, scale: 2
      t.decimal :closing_price, precision: 15, scale: 2
      t.decimal :high_52_week, precision: 15, scale: 2
      t.decimal :low_52_week, precision: 15, scale: 2
      t.decimal :dividend_yield, precision: 8, scale: 2
      t.bigint :shares_outstanding
      t.string :website
      t.string :investor_relations_url
      t.integer :founded_year
      t.boolean :listed, default: true

      t.timestamps
    end
    add_index :companies, :ticker_symbol, unique: true
    add_index :companies, :name
  end
end
